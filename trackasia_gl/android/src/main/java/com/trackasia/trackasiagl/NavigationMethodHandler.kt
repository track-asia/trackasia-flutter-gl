package com.trackasia.trackasiagl

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.speech.tts.TextToSpeech
import android.util.Log
import com.trackasia.android.maps.MapView
import com.trackasia.android.maps.TrackAsiaMap
import com.trackasia.geojson.model.Point
import com.trackasia.navigation.core.location.Location
import com.trackasia.navigation.core.location.replay.ReplayRouteLocationEngine
import com.trackasia.navigation.core.milestone.BannerInstructionMilestone
import com.trackasia.navigation.core.milestone.Milestone
import com.trackasia.navigation.core.milestone.MilestoneEventListener
import com.trackasia.navigation.core.milestone.VoiceInstructionMilestone
import com.trackasia.navigation.core.models.DirectionsResponse
import com.trackasia.navigation.core.models.DirectionsRoute
import com.trackasia.navigation.core.models.RouteOptions
import com.trackasia.navigation.core.navigation.AndroidTrackAsiaNavigation
import com.trackasia.navigation.core.navigation.NavigationEventListener
import com.trackasia.navigation.core.navigation.TrackAsiaNavigation
import com.trackasia.navigation.core.navigation.TrackAsiaNavigationOptions
import com.trackasia.navigation.core.offroute.OffRouteListener
import com.trackasia.navigation.core.routeprogress.ProgressChangeListener
import com.trackasia.navigation.core.routeprogress.RouteProgress
import com.trackasia.navigation.core.utils.RouteUtils
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.IOException
import java.util.Locale
import okhttp3.Call
import okhttp3.Callback
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.Response

class NavigationMethodHandler(private val context: Context) : MethodChannel.MethodCallHandler {
    companion object {
        private const val TAG = "NavigationMethodHandler"
        private const val ACCESS_TOKEN = "public_key"
    }

    private val mainHandler = Handler(Looper.getMainLooper())
    private val routeUtils = RouteUtils()
    private var eventSink: EventChannel.EventSink? = null
    private var navigation: TrackAsiaNavigation? = null
    private var replayEngine: ReplayRouteLocationEngine? = null
    private var textToSpeech: TextToSpeech? = null
    private var isTextToSpeechReady = false
    private var currentRoute: DirectionsRoute? = null
    private var currentDestination: Point? = null
    private var currentOptions = SessionOptions()
    private var latestProgress: Map<String, Any?>? = null
    private var isNavigationActive = false
    private var isMuted = false
    private var rerouteInFlight = false
    private var arrivalEmitted = false

    fun setEventSink(sink: EventChannel.EventSink?) {
        eventSink = sink
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "navigation#calculateRoute", "calculateRoute" -> calculateRoute(call, result)
            "navigation#start", "startNavigation" -> startNavigation(call, result)
            "navigation#stop", "stopNavigation", "navigation#pause" -> stopNavigation(result)
            "navigation#resume" -> postResult(result) { success(null) }
            "navigation#isActive", "isNavigationActive" -> postResult(result) { success(isNavigationActive) }
            "navigation#getProgress", "getCurrentRoute" -> postResult(result) { success(latestProgress) }
            "navigation#setMuted" -> setMuted(call, result)
            "navigationMapRoute#addRoute",
            "navigationMapRoute#addRoutes",
            "navigationMapRoute#removeRoute",
            "navigationMapRoute#clearRoutes",
            "navigationMapRoute#setVisibility",
            "navigationMapRoute#fitCameraToRoutes" -> postResult(result) {
                error(
                    "UNSUPPORTED_NAVIGATION_MAP_ROUTE",
                    "Navigation route rendering belongs to Flutter in headless navigation mode.",
                    null
                )
            }
            else -> result.notImplemented()
        }
    }

    private fun calculateRoute(call: MethodCall, result: MethodChannel.Result) {
        val waypoints = call.argument<List<List<Number>>>("waypoints")
        if (waypoints == null || waypoints.size < 2 || waypoints.any { it.size < 2 }) {
            postResult(result) {
                error("INVALID_WAYPOINTS", "At least two latitude/longitude waypoints are required.", null)
            }
            return
        }

        val origin = pointFromLatLng(waypoints.first())
        val destination = pointFromLatLng(waypoints.last())
        if (origin == null || destination == null) {
            postResult(result) { error("INVALID_WAYPOINTS", "Waypoint coordinates are invalid.", null) }
            return
        }

        val options = SessionOptions.from(call.argument<Map<String, Any?>>("options"))
        requestRoute(origin, destination, options, { route ->
            currentRoute = route
            currentDestination = destination
            currentOptions = options
            postResult(result) { success(route.toFlutterMap()) }
        }, { code, message ->
            postResult(result) { error(code, message, null) }
        })
    }

    private fun startNavigation(call: MethodCall, result: MethodChannel.Result) {
        val route = currentRoute
        if (route == null) {
            postResult(result) {
                error("ROUTE_REQUIRED", "Calculate a route before starting navigation.", null)
            }
            return
        }

        val options = SessionOptions.from(call.argument<Map<String, Any?>>("options"), currentOptions)
        stopNavigationInternal(emitEnded = false)

        try {
            currentOptions = options
            isMuted = !options.enableVoiceGuidance
            arrivalEmitted = false
            rerouteInFlight = false
            latestProgress = null

            val locationEngine = if (options.simulateRoute) {
                ReplayRouteLocationEngine().also { it.assign(route) }
            } else {
                null
            }
            val navigationInstance = if (locationEngine == null) {
                AndroidTrackAsiaNavigation(context.applicationContext, TrackAsiaNavigationOptions())
            } else {
                AndroidTrackAsiaNavigation(
                    context.applicationContext,
                    TrackAsiaNavigationOptions(),
                    locationEngine
                )
            }

            replayEngine = locationEngine
            navigation = navigationInstance
            attachListeners(navigationInstance)
            initializeTextToSpeech(options.language)
            navigationInstance.startNavigation(route)
            isNavigationActive = true
            emit("navigationStarted", mapOf("simulateRoute" to options.simulateRoute))
            postResult(result) { success(mapOf("success" to true, "simulateRoute" to options.simulateRoute)) }
        } catch (exception: Exception) {
            Log.e(TAG, "Unable to start headless navigation", exception)
            stopNavigationInternal(emitEnded = false)
            emit("navigationError", mapOf("message" to (exception.message ?: "Unable to start navigation")))
            postResult(result) {
                error("NAVIGATION_START_ERROR", exception.message ?: "Unable to start navigation", null)
            }
        }
    }

    private fun stopNavigation(result: MethodChannel.Result) {
        stopNavigationInternal(emitEnded = true)
        postResult(result) { success(true) }
    }

    private fun setMuted(call: MethodCall, result: MethodChannel.Result) {
        isMuted = call.argument<Boolean>("muted") ?: false
        if (isMuted) {
            textToSpeech?.stop()
        }
        postResult(result) { success(isMuted) }
    }

    private fun attachListeners(navigationInstance: TrackAsiaNavigation) {
        navigationInstance.addProgressChangeListener(ProgressChangeListener { location, routeProgress ->
            val progress = routeProgress.toFlutterMap(location)
            latestProgress = progress
            emit("routeProgress", progress)
        })
        navigationInstance.addMilestoneEventListener(MilestoneEventListener { routeProgress, _, milestone ->
            handleMilestone(routeProgress, milestone)
        })
        navigationInstance.addOffRouteListener(OffRouteListener { location -> handleOffRoute(location) })
        navigationInstance.addNavigationEventListener(NavigationEventListener { running ->
            isNavigationActive = running
        })
    }

    private fun handleMilestone(routeProgress: RouteProgress, milestone: Milestone) {
        when (milestone) {
            is BannerInstructionMilestone -> {
                val instruction = milestone.bannerInstructions ?: return
                emit(
                    "bannerInstruction",
                    mapOf(
                        "primaryText" to instruction.primary.text,
                        "secondaryText" to instruction.secondary?.text,
                        "nextText" to instruction.sub?.text,
                        "distanceAlongGeometry" to routeProgress.currentLegProgress.currentStepProgress.distanceRemaining,
                        "maneuverType" to instruction.primary.type?.name,
                        "maneuverModifier" to instruction.primary.modifier?.name
                    )
                )
            }
            is VoiceInstructionMilestone -> {
                val announcement = milestone.announcement.orEmpty()
                if (announcement.isNotBlank()) {
                    emit(
                        "voiceInstruction",
                        mapOf(
                            "text" to announcement,
                            "distanceAlongGeometry" to routeProgress.currentLegProgress.currentStepProgress.distanceRemaining
                        )
                    )
                    if (!isMuted && isTextToSpeechReady) {
                        textToSpeech?.speak(announcement, TextToSpeech.QUEUE_FLUSH, null, "trackasia-navigation")
                    }
                }
            }
        }

        if (!arrivalEmitted && routeUtils.isArrivalEvent(routeProgress, milestone)) {
            arrivalEmitted = true
            emit("arrival", latestProgress ?: routeProgress.toFlutterMap(null))
        }
    }

    private fun handleOffRoute(location: Location) {
        emit("offRoute", mapOf("latitude" to location.latitude, "longitude" to location.longitude))
        if (!currentOptions.enableRerouting || rerouteInFlight || !isNavigationActive) {
            return
        }

        val destination = currentDestination ?: return
        rerouteInFlight = true
        emit("rerouting")
        requestRoute(location.point, destination, currentOptions, { route ->
            currentRoute = route
            replayEngine?.assign(route)
            navigation?.startNavigation(route)
            rerouteInFlight = false
            emit("reroute", route.toFlutterMap())
        }, { code, message ->
            rerouteInFlight = false
            emit("navigationError", mapOf("code" to code, "message" to message))
        })
    }

    private fun requestRoute(
        origin: Point,
        destination: Point,
        options: SessionOptions,
        onSuccess: (DirectionsRoute) -> Unit,
        onFailure: (String, String) -> Unit
    ) {
        val coordinates = "${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}"
        val url = "https://maps.track-asia.com/route/v1/${options.profile}/$coordinates.json" +
            "?geometries=polyline6&steps=true&overview=full&key=$ACCESS_TOKEN"

        OkHttpClient().newCall(
            Request.Builder()
                .header("User-Agent", "TrackAsia Flutter Navigation Plugin")
                .url(url)
                .build()
        ).enqueue(object : Callback {
            override fun onFailure(call: Call, exception: IOException) {
                Log.e(TAG, "Route request failed", exception)
                onFailure("ROUTE_ERROR", exception.message ?: "Route request failed")
            }

            override fun onResponse(call: Call, response: Response) {
                response.use {
                    if (!it.isSuccessful) {
                        onFailure("ROUTE_ERROR", "Route request failed with code ${it.code}")
                        return
                    }

                    try {
                        val body = it.body?.string().orEmpty()
                        val route = DirectionsResponse.fromJson(body).routes.firstOrNull()
                        if (route == null || route.geometry.isEmpty()) {
                            onFailure("NO_ROUTES", "No navigable route returned by TrackAsia.")
                            return
                        }
                        onSuccess(
                            route.copy(
                                routeOptions = RouteOptions(
                                    baseUrl = "https://maps.track-asia.com/route/v1",
                                    profile = options.profile,
                                    user = "trackasia",
                                    accessToken = ACCESS_TOKEN,
                                    voiceInstructions = true,
                                    bannerInstructions = true,
                                    language = options.language ?: "vi",
                                    coordinates = listOf(origin, destination),
                                    geometries = "polyline6",
                                    steps = true,
                                    overview = "full",
                                    requestUuid = "trackasia-nav-${System.currentTimeMillis()}"
                                )
                            )
                        )
                    } catch (exception: Exception) {
                        Log.e(TAG, "Route response parse failed", exception)
                        onFailure("PARSE_ERROR", exception.message ?: "Route response parse failed")
                    }
                }
            }
        })
    }

    private fun initializeTextToSpeech(language: String?) {
        textToSpeech?.shutdown()
        isTextToSpeechReady = false
        textToSpeech = TextToSpeech(context.applicationContext) { status ->
            isTextToSpeechReady = status == TextToSpeech.SUCCESS
            if (isTextToSpeechReady && language != null) {
                textToSpeech?.language = Locale.forLanguageTag(language.replace('_', '-'))
            }
        }
    }

    private fun stopNavigationInternal(emitEnded: Boolean) {
        val wasActive = isNavigationActive
        isNavigationActive = false
        rerouteInFlight = false
        navigation?.onDestroy()
        navigation = null
        replayEngine = null
        textToSpeech?.stop()
        textToSpeech?.shutdown()
        textToSpeech = null
        isTextToSpeechReady = false
        if (emitEnded && wasActive) {
            emit("navigationEnded")
        }
    }

    private fun emit(type: String, data: Map<String, Any?> = emptyMap()) {
        mainHandler.post { eventSink?.success(HashMap(data).apply { put("type", type) }) }
    }

    private fun postResult(result: MethodChannel.Result, block: MethodChannel.Result.() -> Unit) {
        mainHandler.post { result.block() }
    }

    fun setMapView(mapView: MapView?) = Unit

    fun setTrackAsiaMap(trackasiaMap: TrackAsiaMap?) = Unit

    fun cleanup() {
        stopNavigationInternal(emitEnded = false)
        eventSink = null
        currentRoute = null
        currentDestination = null
        latestProgress = null
    }

    private fun pointFromLatLng(values: List<Number>): Point? {
        val latitude = values[0].toDouble()
        val longitude = values[1].toDouble()
        return if (latitude.isFinite() && longitude.isFinite()) {
            Point(longitude = longitude, latitude = latitude)
        } else {
            null
        }
    }

    private fun DirectionsRoute.toFlutterMap(): Map<String, Any?> = mapOf(
        "geometry" to geometry,
        "distance" to distance,
        "duration" to duration,
        "waypoints" to (routeOptions?.coordinates?.map { point ->
            mapOf("latitude" to point.latitude, "longitude" to point.longitude)
        } ?: emptyList<Map<String, Double>>())
    )

    private fun RouteProgress.toFlutterMap(location: Location?): Map<String, Any?> = mapOf(
        "latitude" to location?.latitude,
        "longitude" to location?.longitude,
        "bearing" to location?.bearing,
        "speed" to location?.speedMetersPerSeconds,
        "distanceRemaining" to distanceRemaining,
        "durationRemaining" to durationRemaining,
        "distanceTraveled" to distanceTraveled,
        "fractionTraveled" to fractionTraveled,
        "stepDistanceRemaining" to currentLegProgress.currentStepProgress.distanceRemaining,
        "currentStepIndex" to stepIndex,
        "currentLegIndex" to legIndex,
        "currentRoadName" to currentLegProgress.currentStep.name
    )

    private data class SessionOptions(
        val enableVoiceGuidance: Boolean = true,
        val enableRerouting: Boolean = true,
        val simulateRoute: Boolean = false,
        val profile: String = "car",
        val language: String? = "vi"
    ) {
        companion object {
            fun from(values: Map<String, Any?>?, fallback: SessionOptions = SessionOptions()): SessionOptions {
                if (values == null) return fallback
                return SessionOptions(
                    enableVoiceGuidance = values["enableVoiceGuidance"] as? Boolean ?: fallback.enableVoiceGuidance,
                    enableRerouting = values["enableRerouting"] as? Boolean ?: fallback.enableRerouting,
                    simulateRoute = values["simulateRoute"] as? Boolean ?: fallback.simulateRoute,
                    profile = values["profile"] as? String ?: fallback.profile,
                    language = values["language"] as? String ?: fallback.language
                )
            }
        }
    }
}
