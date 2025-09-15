package com.trackasia.trackasiagl

import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import com.trackasia.navigation.android.navigation.ui.v5.NavigationLauncher
import com.trackasia.navigation.android.navigation.ui.v5.NavigationLauncherOptions
import com.trackasia.navigation.android.navigation.ui.v5.route.NavigationMapRoute
import com.trackasia.navigation.core.navigation.TrackAsiaNavigation
import com.trackasia.navigation.core.routeprogress.ProgressChangeListener
import com.trackasia.navigation.core.routeprogress.RouteProgress
import com.trackasia.geojson.Point
import com.trackasia.navigation.core.models.DirectionsResponse
import com.trackasia.navigation.core.models.DirectionsRoute
import com.trackasia.navigation.core.models.RouteOptions
import com.trackasia.navigation.core.models.RouteLeg
import com.trackasia.android.maps.MapView
import com.trackasia.android.maps.TrackAsiaMap
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.Callback
import okhttp3.Call
import okhttp3.Response
import java.io.IOException
import com.google.gson.Gson


class NavigationMethodHandler(private val context: Context) : MethodChannel.MethodCallHandler {
    companion object {
        private const val TAG = "NavigationMethodHandler"
        private const val ACCESS_TOKEN = "public_key" // Default token, should be configurable
    }
    
    private var trackasiaNavigation: TrackAsiaNavigation? = null
    private var currentRoute: DirectionsRoute? = null
    private var navigationMapRoute: NavigationMapRoute? = null
    private var isNavigationActive = false
    private var mapView: com.trackasia.android.maps.MapView? = null
    private var trackasiaMap: com.trackasia.android.maps.TrackAsiaMap? = null

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "navigation#calculateRoute" -> calculateRoute(call, result)
            "calculateRoute" -> calculateRoute(call, result) // Keep backward compatibility
            "navigation#start" -> startNavigation(call, result)
            "startNavigation" -> startNavigation(call, result) // Keep backward compatibility
            "navigation#stop" -> stopNavigation(result)
            "stopNavigation" -> stopNavigation(result) // Keep backward compatibility
            "navigation#pause" -> stopNavigation(result) // Pause same as stop for now
            "navigation#resume" -> result.success(null) // Resume not implemented yet
            "navigation#isActive" -> result.success(isNavigationActive)
            "isNavigationActive" -> result.success(isNavigationActive) // Keep backward compatibility
            "navigation#getProgress" -> getCurrentRoute(result)
            "getCurrentRoute" -> getCurrentRoute(result) // Keep backward compatibility
            // NavigationMapRoute methods
            "navigationMapRoute#addRoute" -> addNavigationRoute(call, result)
            "navigationMapRoute#addRoutes" -> addNavigationRoutes(call, result)
            "navigationMapRoute#removeRoute" -> removeNavigationRoute(call, result)
            "navigationMapRoute#clearRoutes" -> clearNavigationRoutes(result)
            "navigationMapRoute#setVisibility" -> setRouteVisibility(call, result)
            "navigationMapRoute#fitCameraToRoutes" -> fitCameraToRoutes(call, result)
            else -> result.notImplemented()
        }
    }

    private fun calculateRoute(call: MethodCall, result: MethodChannel.Result) {
        try {
            val waypoints = call.argument<List<List<Double>>>("waypoints")
            if (waypoints == null || waypoints.isEmpty()) {
                result.error("INVALID_WAYPOINTS", "Waypoints list cannot be empty", null)
                return
            }
            
            if (waypoints.size < 2) {
                result.error("INVALID_WAYPOINTS", "At least 2 waypoints are required", null)
                return
            }

            // Convert waypoints to Point objects
            // Check if each waypoint has at least 2 elements (lat, lng)
            if (waypoints[0].isEmpty() || waypoints[0].size < 2) {
                result.error("INVALID_WAYPOINT_FORMAT", "First waypoint must have at least 2 coordinates (lat, lng)", null)
                return
            }
            
            if (waypoints[1].isEmpty() || waypoints[1].size < 2) {
                result.error("INVALID_WAYPOINT_FORMAT", "Second waypoint must have at least 2 coordinates (lat, lng)", null)
                return
            }
            
            // waypoints from Flutter: [latitude, longitude]
            // Point.fromLngLat expects: (longitude, latitude)
            val origin = Point.fromLngLat(waypoints[0][1], waypoints[0][0]) // lng=waypoints[0][1], lat=waypoints[0][0]
            val destination = Point.fromLngLat(waypoints[1][1], waypoints[1][0]) // lng=waypoints[1][1], lat=waypoints[1][0]
            
            Log.d(TAG, "Calculating route from ${waypoints[0]} to ${waypoints[1]}")

            // Build TrackAsia API URL v1 (like MapMultiPointFragment)
            val profile = "car" // Can be: car, moto, walk, truck
            val baseUrl = "https://maps.track-asia.com/route/v1/$profile"
            val coordinates = "${origin.longitude()},${origin.latitude()};${destination.longitude()},${destination.latitude()}"
            val url = "$baseUrl/$coordinates.json?geometries=polyline6&steps=true&overview=full&key=public_key"
            
            Log.d(TAG, "Requesting route: $url")
            
            // Make HTTP request
            val client = OkHttpClient()
            val request = Request.Builder()
                .header("User-Agent", "TrackAsia Flutter Navigation Plugin")
                .url(url)
                .build()
                
            client.newCall(request).enqueue(object : Callback {
                override fun onFailure(call: Call, e: IOException) {
                    Log.e(TAG, "Route calculation failed", e)
                    result.error("ROUTE_ERROR", "Route calculation failed: ${e.message}", null)
                }
                
                override fun onResponse(call: Call, response: Response) {
                    response.use {
                        try {
                            if (!response.isSuccessful) {
                                val errorBody = response.body?.string() ?: "No error body"
                                Log.e(TAG, "Route calculation failed with code: ${response.code}")
                                Log.e(TAG, "Response headers: ${response.headers}")
                                Log.e(TAG, "Error response body: $errorBody")
                                Log.e(TAG, "Request URL: ${response.request.url}")
                                result.error("ROUTE_ERROR", "Route calculation failed with code: ${response.code}. Error: $errorBody", null)
                                return
                            }
                        
                        response.body?.string()?.let { json ->
                            try {
                                Log.d(TAG, "Processing route response: ${json.take(100)}...")
                                
                                // Use DirectionsResponse.fromJson like MapMultiPointFragment
                                val trackasiaResponse = DirectionsResponse.fromJson(json)
                                
                                if (trackasiaResponse.routes.isEmpty()) {
                                    Log.e(TAG, "No routes found in response")
                                    result.error("NO_ROUTES", "No routes found in response", null)
                                    return
                                }
                                
                                val firstRoute = trackasiaResponse.routes.first()
                                if (firstRoute.geometry.isEmpty()) {
                                    Log.e(TAG, "Route geometry is empty")
                                    result.error("EMPTY_GEOMETRY", "Route geometry is empty", null)
                                    return
                                }
                                
                                Log.d(TAG, "Route found: Distance=${firstRoute.distance}m, Duration=${firstRoute.duration}s")
                                
                                // Create a copy of the route with proper RouteOptions - match MapWayPointFragment.kt line 589-604
                                val routeWithOptions = firstRoute.copy(
                                    routeOptions = RouteOptions(
                                        baseUrl = "https://maps.track-asia.com/route/v1",
                                        profile = "car",
                                        user = "trackasia",
                                        accessToken = "public_key",
                                        voiceInstructions = true,
                                        bannerInstructions = true,
                                        language = "vi",
                                        coordinates = listOf(origin, destination),
                                        geometries = "polyline6",
                                        steps = true,
                                        overview = "full",
                                        requestUuid = "trackasia-nav-${System.currentTimeMillis()}"
                                    )
                                )
                                
                                // Store current route for navigation - match MapWayPointFragment.kt line 642
                                currentRoute = routeWithOptions
                                Log.d(TAG, "Current route stored for navigation: ${currentRoute?.distance}m")
                                
                                // Display route on map using NavigationMapRoute like MapMultiPointFragment
                                // Must run on UI thread to avoid CalledFromWorkerThreadException
                                Handler(Looper.getMainLooper()).post {
                                    val currentMapView = mapView
                                    val currentTrackasiaMap = trackasiaMap
                                    if (navigationMapRoute == null && currentMapView != null && currentTrackasiaMap != null) {
                                        navigationMapRoute = NavigationMapRoute(null, currentMapView, currentTrackasiaMap)
                                    }
                                    
                                    navigationMapRoute?.let { navMapRoute ->
                                        navMapRoute.removeRoute()
                                        navMapRoute.addRoutes(listOf(routeWithOptions))
                                        Log.d(TAG, "Route displayed on map successfully")
                                    } ?: run {
                                        Log.w(TAG, "NavigationMapRoute not available, map may not be ready")
                                    }
                                }
                                
                                // Return route data for Flutter
                                val routeMap = hashMapOf<String, Any?>(
                                    "geometry" to routeWithOptions.geometry,
                                    "distance" to routeWithOptions.distance,
                                    "duration" to routeWithOptions.duration,
                                    "weight" to (routeWithOptions.weight ?: routeWithOptions.duration),
                                    "waypoints" to listOf(
                                        mapOf(
                                            "latitude" to origin.latitude(),
                                            "longitude" to origin.longitude()
                                        ),
                                        mapOf(
                                            "latitude" to destination.latitude(),
                                            "longitude" to destination.longitude()
                                        )
                                    )
                                )
                                
                                Log.d(TAG, "Route calculated and displayed successfully")
                                result.success(routeMap)
                            } catch (e: Exception) {
                                Log.e(TAG, "Error parsing route response", e)
                                result.error("PARSE_ERROR", "Error parsing route response: ${e.message}", null)
                            }
                        } ?: run {
                            Log.e(TAG, "Empty response body")
                            result.error("EMPTY_RESPONSE", "Empty response body", null)
                        }
                        } catch (e: Exception) {
                            Log.e(TAG, "Unexpected error in onResponse", e)
                            result.error("UNEXPECTED_ERROR", "Unexpected error: ${e.message}", null)
                        }
                    }
                }
            })
        } catch (e: Exception) {
            Log.e(TAG, "Error calculating route", e)
            result.error("CALCULATION_ERROR", "Error calculating route: ${e.message}", null)
        }
    }

    private fun startNavigation(call: MethodCall, result: MethodChannel.Result) {
        try {
            if (currentRoute == null) {
                result.error("NO_ROUTE", "No route available. Please calculate a route first.", null)
                return
            }

            // Extract navigation options from call
            val routeData = call.argument<Map<String, Any>>("route")
            val options = call.argument<Map<String, Any>>("options") ?: emptyMap()
            val simulateRoute = options["simulateRoute"] as? Boolean ?: false // Default to false for real navigation

            // Get Activity context - this is REQUIRED for NavigationLauncher
            val activityContext = TrackAsiaMapsPlugin.getCurrentActivity()
            if (activityContext == null) {
                Log.e(TAG, "No Activity context available for NavigationLauncher")
                result.error("NAVIGATION_CONTEXT_ERROR", 
                    "Navigation requires Activity context. Please ensure the app is in the foreground and try again.", 
                    mapOf("error_type" to "no_activity_context", "suggestion" to "retry_when_app_active"))
                return
            }

            // Build navigation launch options with custom themes - match MapWayPointFragment.kt line 881-891  
            val launcherOptions = NavigationLauncherOptions.builder()
                .directionsRoute(currentRoute!!)
                .shouldSimulateRoute(simulateRoute)
                .lightThemeResId(R.style.NavigationViewLight)
                .darkThemeResId(R.style.NavigationViewDark)
                .build()

            Log.d(TAG, "Starting navigation with Activity context, simulate: $simulateRoute")
            
            // Note: NavigationActivity may show warning about "Unable to parse resourceUrl mapbox://styles/mapbox/navigation-guidance-day-v4"
            // This is expected as TrackAsia was forked from Mapbox and some default style URLs remain from the original codebase.
            // The warning doesn't affect navigation functionality and can be safely ignored.
            try {
                NavigationLauncher.startNavigation(activityContext, launcherOptions)
                isNavigationActive = true
                Log.d(TAG, "Navigation started successfully using NavigationLauncher")
                
                result.success(mapOf(
                    "success" to true,
                    "simulateRoute" to simulateRoute,
                    "routeDistance" to currentRoute?.distance,
                    "routeDuration" to currentRoute?.duration
                ))
            } catch (e: android.util.AndroidRuntimeException) {
                Log.e(TAG, "NavigationLauncher failed with AndroidRuntimeException", e)
                result.error("NAVIGATION_START_ERROR", "Failed to start navigation: ${e.message}", null)
            } catch (e: Exception) {
                Log.e(TAG, "NavigationLauncher failed with unexpected exception", e)
                result.error("NAVIGATION_START_ERROR", "Failed to start navigation: ${e.message}", null)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error starting navigation", e)
            result.error("START_ERROR", "Error starting navigation: ${e.message}", null)
        }
    }

    private fun stopNavigation(result: MethodChannel.Result) {
        try {
            // NavigationLauncher starts a separate activity, so we just mark as inactive
            // The actual navigation stopping is handled by the NavigationActivity itself
            isNavigationActive = false
            Log.d(TAG, "Navigation stopped successfully")
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping navigation", e)
            result.error("STOP_ERROR", "Error stopping navigation: ${e.message}", null)
        }
    }

    private fun getCurrentRoute(result: MethodChannel.Result) {
        try {
            val route = currentRoute
            if (route != null) {
                val routeMap = hashMapOf<String, Any?>(
                "geometry" to route.geometry,
                "distance" to route.distance,
                "duration" to route.duration
            )
                result.success(routeMap)
            } else {
                result.success(null)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error getting current route", e)
            result.error("GET_ROUTE_ERROR", "Error getting current route: ${e.message}", null)
        }
    }

    // NavigationMapRoute methods
    private fun addNavigationRoute(call: MethodCall, result: MethodChannel.Result) {
        try {
            val routeData = call.argument<Map<String, Any>>("route")
            val styleData = call.argument<Map<String, Any>>("style")
            val isPrimary = call.argument<Boolean>("isPrimary") ?: true
            val routeId = call.argument<String>("routeId") ?: "route_${System.currentTimeMillis()}"
            
            if (routeData == null) {
                result.error("INVALID_ROUTE", "Route data is required", null)
                return
            }
            
            // Extract route geometry
            val geometry = routeData["geometry"] as? String
            if (geometry == null) {
                result.error("INVALID_GEOMETRY", "Route geometry is required", null)
                return
            }
            
            // Extract other route data
            val distance = (routeData["distance"] as? Number)?.toDouble() ?: 0.0
            val duration = (routeData["duration"] as? Number)?.toDouble() ?: 0.0
            val waypoints = routeData["waypoints"] as? List<Map<String, Any>> ?: emptyList()
            
                // Convert Flutter route data to proper DirectionsRoute format
                // This matches the exact process from MapWayPointFragment.kt processRouteResponse
                val directionsRoute = try {
                    // Create RouteOptions exactly like MapWayPointFragment.kt line 589-603
                    val routeOptions = RouteOptions(
                        baseUrl = "https://maps.track-asia.com/route/v1",
                        profile = "car",
                        user = "trackasia", 
                        accessToken = "public_key",
                        voiceInstructions = true,
                        bannerInstructions = true,
                        language = "vi",
                        coordinates = waypoints.mapNotNull { waypoint ->
                            val lat = waypoint["latitude"] as? Double
                            val lng = waypoint["longitude"] as? Double
                            if (lat != null && lng != null) {
                                Point.fromLngLat(lng, lat)
                            } else null
                        },
                        geometries = "polyline6",
                        steps = true,
                        overview = "full",
                        requestUuid = "trackasia-nav-${System.currentTimeMillis()}"
                    )
                    
                    // Create DirectionsRoute with proper structure - match MapWayPointFragment.kt format
                    createDirectionsRouteFromNativeData(geometry, distance, duration, waypoints, routeOptions)
                } catch (e: Exception) {
                    Log.e(TAG, "Error creating DirectionsRoute with RouteOptions", e)
                    null
                }
                
                if (directionsRoute == null) {
                    Log.e(TAG, "Failed to create DirectionsRoute from provided data")
                    result.error("ROUTE_CREATION_FAILED", "Failed to create DirectionsRoute from provided data", null)
                    return
                }
                
                // Store current route for navigation like MapWayPointFragment.kt line 642
                currentRoute = directionsRoute
                
                // Use NavigationMapRoute exactly like MapWayPointFragment.kt line 179-184
                // Must run on UI thread to avoid CalledFromWorkerThreadException
                Handler(Looper.getMainLooper()).post {
                    val currentMapView = mapView
                    val currentTrackasiaMap = trackasiaMap
                    if (navigationMapRoute == null && currentMapView != null && currentTrackasiaMap != null) {
                        navigationMapRoute = NavigationMapRoute(null, currentMapView, currentTrackasiaMap)
                        Log.d(TAG, "NavigationMapRoute initialized successfully")
                    }
                    
                    navigationMapRoute?.let { navMapRoute ->
                    try {
                        Log.d(TAG, "About to add route to NavigationMapRoute. Route distance: ${directionsRoute.distance}m")
                        
                        // Additional safety checks before calling native methods
                        if (directionsRoute.geometry.isNullOrEmpty()) {
                            Log.e(TAG, "DirectionsRoute geometry is null or empty, cannot add route")
                            result.error("INVALID_ROUTE_GEOMETRY", "Route geometry is null or empty", null)
                            return@post
                        }
                        
                        if (isPrimary) {
                            // Clear existing routes and add new one - match MapWayPointFragment.kt line 618-620
                            navMapRoute.removeRoute()
                            Log.d(TAG, "Cleared existing routes, now adding primary route")
                            navMapRoute.addRoute(directionsRoute)
                        } else {
                            // Add as alternative route
                            Log.d(TAG, "Adding alternative route")
                            navMapRoute.addRoute(directionsRoute)
                        }
                        
                        Log.d(TAG, "Navigation route drawn successfully: $routeId")
                        result.success(mapOf("routeId" to routeId, "success" to true))
                    } catch (e: IndexOutOfBoundsException) {
                        Log.e(TAG, "IndexOutOfBoundsException in NavigationMapRoute.addRoute(): ${e.message}", e)
                        result.error("INDEX_OUT_OF_BOUNDS_ERROR", "Index out of bounds error in native NavigationMapRoute.addRoute(): ${e.message}. This may be caused by empty route data or invalid geometry.", e.stackTrace.joinToString("\n"))
                    } catch (e: Exception) {
                        Log.e(TAG, "Error in NavigationMapRoute.addRoute(): ${e.message}", e)
                        result.error("NATIVE_ADD_ROUTE_ERROR", "Error in native NavigationMapRoute.addRoute(): ${e.message}", e.stackTrace.joinToString("\n"))
                    }
                 } ?: run {
                     result.error("MAP_NOT_READY", "Map or NavigationMapRoute not initialized", null)
                 }
                }
        } catch (e: Exception) {
            Log.e(TAG, "Error adding navigation route", e)
            result.error("ADD_ROUTE_ERROR", "Error adding navigation route: ${e.message}", null)
        }
    }
    
    private fun addNavigationRoutes(call: MethodCall, result: MethodChannel.Result) {
        try {
            val routesData = call.argument<List<Map<String, Any>>>("routes")
            val primaryStyle = call.argument<Map<String, Any>>("primaryStyle")
            val alternativeStyle = call.argument<Map<String, Any>>("alternativeStyle")
            val config = call.argument<Map<String, Any>>("config")
            
            if (routesData == null || routesData.isEmpty()) {
                result.error("INVALID_ROUTES", "Routes data is required", null)
                return
            }
            
            val directionsRoutes = mutableListOf<com.trackasia.navigation.core.models.DirectionsRoute>()
            val routeIds = mutableListOf<String>()
            
            // Convert all route data to DirectionsRoute objects
            routesData.forEachIndexed { index, routeData ->
                val geometry = routeData["geometry"] as? String
                val distance = (routeData["distance"] as? Number)?.toDouble() ?: 0.0
                val duration = (routeData["duration"] as? Number)?.toDouble() ?: 0.0
                val waypoints = routeData["waypoints"] as? List<Map<String, Any>> ?: emptyList()
                
                if (geometry != null) {
                    // Create RouteOptions for each route
                    val routeOptions = RouteOptions(
                        baseUrl = "https://maps.track-asia.com/route/v1",
                        profile = "car",
                        user = "trackasia",
                        accessToken = "public_key",
                        voiceInstructions = true,
                        bannerInstructions = true,
                        language = "vi",
                        coordinates = waypoints.mapNotNull { waypoint ->
                            val lat = waypoint["latitude"] as? Double
                            val lng = waypoint["longitude"] as? Double
                            if (lat != null && lng != null) {
                                Point.fromLngLat(lng, lat)
                            } else null
                        },
                        geometries = "polyline6",
                        steps = true,
                        overview = "full",
                        requestUuid = "trackasia-nav-${System.currentTimeMillis()}_$index"
                    )
                    
                    val directionsRoute = createDirectionsRouteFromNativeData(geometry, distance, duration, waypoints, routeOptions)
                    if (directionsRoute != null) {
                        directionsRoutes.add(directionsRoute)
                        val routeId = "route_${System.currentTimeMillis()}_$index"
                        routeIds.add(routeId)
                    }
                }
            }
            
            if (directionsRoutes.isNotEmpty()) {
                // Use NavigationMapRoute to draw all routes
                // Must run on UI thread to avoid CalledFromWorkerThreadException
                Handler(Looper.getMainLooper()).post {
                    val currentMapView = mapView
                    val currentTrackasiaMap = trackasiaMap
                    if (navigationMapRoute == null && currentMapView != null && currentTrackasiaMap != null) {
                        navigationMapRoute = com.trackasia.navigation.android.navigation.ui.v5.route.NavigationMapRoute(
                            null, currentMapView, currentTrackasiaMap
                        )
                    }
                    
                    navigationMapRoute?.let { navMapRoute ->
                        try {
                            Log.d(TAG, "About to add ${directionsRoutes.size} routes to NavigationMapRoute")
                            directionsRoutes.forEachIndexed { index, route ->
                                Log.d(TAG, "Route ${index + 1}: Distance=${route.distance}m, Duration=${route.duration}s")
                            }
                            
                            // Additional safety checks before calling native methods
                            if (directionsRoutes.isEmpty()) {
                                Log.e(TAG, "DirectionsRoutes list is empty, cannot add routes")
                                result.error("EMPTY_ROUTES_LIST", "Routes list is empty", null)
                                return@post
                            }
                            
                            // Check each route for valid geometry
                            for ((index, route) in directionsRoutes.withIndex()) {
                                if (route.geometry.isNullOrEmpty()) {
                                    Log.e(TAG, "DirectionsRoute at index $index has null or empty geometry")
                                    result.error("INVALID_ROUTE_GEOMETRY", "Route at index $index has null or empty geometry", null)
                                    return@post
                                }
                            }
                            
                            // Clear existing routes - match MapWayPointFragment.kt
                            navMapRoute.removeRoute()
                            Log.d(TAG, "Cleared existing routes")
                            
                            // Add all routes using addRoutes method - match MapWayPointFragment.kt line 619
                            // Store first route as currentRoute for navigation
                            currentRoute = directionsRoutes.first()
                            navMapRoute.addRoutes(directionsRoutes)
                            
                            Log.d(TAG, "Navigation routes drawn successfully: ${routeIds.size} routes")
                            result.success(mapOf("routeIds" to routeIds, "success" to true))
                        } catch (e: IndexOutOfBoundsException) {
                            Log.e(TAG, "IndexOutOfBoundsException in NavigationMapRoute.addRoutes(): ${e.message}", e)
                            result.error("INDEX_OUT_OF_BOUNDS_ERROR", "Index out of bounds error in native NavigationMapRoute.addRoutes(): ${e.message}. This may be caused by empty route data or invalid geometry.", e.stackTrace.joinToString("\n"))
                        } catch (e: Exception) {
                            Log.e(TAG, "Error in NavigationMapRoute.addRoutes(): ${e.message}", e)
                            result.error("NATIVE_ADD_ROUTES_ERROR", "Error in native NavigationMapRoute.addRoutes(): ${e.message}", e.stackTrace.joinToString("\n"))
                        }
                    } ?: run {
                        result.error("MAP_NOT_READY", "Map or NavigationMapRoute not initialized", null)
                    }
                }
            } else {
                result.error("ROUTE_CREATION_ERROR", "Failed to create DirectionsRoute objects", null)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error adding navigation routes", e)
            result.error("ADD_ROUTES_ERROR", "Error adding navigation routes: ${e.message}", null)
        }
    }
    
    private fun removeNavigationRoute(call: MethodCall, result: MethodChannel.Result) {
        try {
            val routeId = call.argument<String>("routeId")
            
            if (routeId == null) {
                result.error("INVALID_ROUTE_ID", "Route ID is required", null)
                return
            }
            
            // Remove route from map display
            // Must run on UI thread to avoid CalledFromWorkerThreadException
            Handler(Looper.getMainLooper()).post {
                navigationMapRoute?.removeRoute()
                Log.d(TAG, "Navigation route removed: $routeId")
                result.success(mapOf("routeId" to routeId, "success" to true))
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error removing navigation route", e)
            result.error("REMOVE_ROUTE_ERROR", "Error removing navigation route: ${e.message}", null)
        }
    }
    
    private fun clearNavigationRoutes(result: MethodChannel.Result) {
        try {
            // Clear all routes from map display
            // Must run on UI thread to avoid CalledFromWorkerThreadException
            Handler(Looper.getMainLooper()).post {
                navigationMapRoute?.removeRoute()
                Log.d(TAG, "All navigation routes cleared")
                result.success(mapOf("success" to true))
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error clearing navigation routes", e)
            result.error("CLEAR_ROUTES_ERROR", "Error clearing navigation routes: ${e.message}", null)
        }
    }
    
    private fun setRouteVisibility(call: MethodCall, result: MethodChannel.Result) {
        try {
            val routeId = call.argument<String>("routeId")
            val visible = call.argument<Boolean>("visible") ?: true
            
            if (routeId == null) {
                result.error("INVALID_ROUTE_ID", "Route ID is required", null)
                return
            }
            
            Log.d(TAG, "Route visibility changed: $routeId -> $visible")
            result.success(mapOf("routeId" to routeId, "visible" to visible, "success" to true))
        } catch (e: Exception) {
            Log.e(TAG, "Error setting route visibility", e)
            result.error("VISIBILITY_ERROR", "Error setting route visibility: ${e.message}", null)
        }
    }
    
    private fun fitCameraToRoutes(call: MethodCall, result: MethodChannel.Result) {
        try {
            val routeIds = call.argument<List<String>>("routeIds")
            val padding = call.argument<Map<String, Double>>("padding")
            val animated = call.argument<Boolean>("animated") ?: true
            
            // Calculate bounds from route geometries and fit camera
            Log.d(TAG, "Fitting camera to routes: ${routeIds?.joinToString(", ") ?: "all"}")
            result.success(mapOf("success" to true, "animated" to animated))
        } catch (e: Exception) {
            Log.e(TAG, "Error fitting camera to routes", e)
            result.error("FIT_CAMERA_ERROR", "Error fitting camera to routes: ${e.message}", null)
        }
    }
    
    private fun createDirectionsRouteFromNativeData(
        geometry: String,
        distance: Double,
        duration: Double,
        waypoints: List<Map<String, Any>>,
        routeOptions: RouteOptions
    ): DirectionsRoute? {
        return try {
            // Additional safety checks
            if (geometry.isBlank()) {
                Log.e(TAG, "Cannot create DirectionsRoute: geometry is empty or blank")
                return null
            }
            
            if (waypoints.isEmpty()) {
                Log.e(TAG, "Cannot create DirectionsRoute: waypoints list is empty")
                return null
            }
            
            // Ensure we have at least 2 waypoints
            if (waypoints.size < 2) {
                Log.e(TAG, "Cannot create DirectionsRoute: insufficient waypoints (${waypoints.size}). Need at least 2.")
                return null
            }
            
            // Create DirectionsRoute from the provided data
            val gson = Gson()
            
            // Convert waypoints to proper format
            // Handle both Flutter format {latitude, longitude} and native format {location: [lng, lat], name}
            val waypointsList = waypoints.mapNotNull { waypoint ->
                // Try Flutter format first: {latitude: double, longitude: double}
                val latitude = waypoint["latitude"] as? Double
                val longitude = waypoint["longitude"] as? Double
                
                if (latitude != null && longitude != null) {
                    // Flutter format - convert to expected format
                    mapOf(
                        "location" to listOf(longitude, latitude), // [lng, lat]
                        "name" to ""
                    )
                } else {
                    // Try native format: {location: [lng, lat], name: string}
                    val location = waypoint["location"] as? List<Double>
                    if (location != null && location.size >= 2) {
                        mapOf(
                            "location" to location,
                            "name" to (waypoint["name"] as? String ?: "")
                        )
                    } else {
                        Log.w(TAG, "Waypoint has invalid format. Expected {latitude, longitude} or {location: [lng, lat], name}. Got: $waypoint")
                        null
                    }
                }
            }
            
            // Double check after filtering
            if (waypointsList.size < 2) {
                Log.e(TAG, "Cannot create DirectionsRoute: insufficient valid waypoints after filtering (${waypointsList.size}). Need at least 2.")
                return null
            }
            
            // Create legs array - must have (waypoints.size - 1) legs
            val legsCount = waypointsList.size - 1
            val legDistance = distance / legsCount
            val legDuration = duration / legsCount
            
            val legs = (0 until legsCount).map { legIndex ->
                mapOf(
                    "distance" to legDistance,
                    "duration" to legDuration,
                    "weight" to legDistance,
                    "summary" to "",
                    "steps" to emptyList<Any>()
                )
            }
            
            // Create DirectionsRoute with RouteOptions - match MapWayPointFragment.kt processRouteResponse
            val routeJson = mapOf(
                "geometry" to geometry,
                "distance" to distance,
                "duration" to duration,
                "weight" to distance,
                "weight_name" to "routability",
                "legs" to legs,
                "waypoints" to waypointsList
            )
            
            Log.d(TAG, "Creating DirectionsRoute with ${waypointsList.size} waypoints and ${legs.size} legs")
            Log.d(TAG, "Using RouteOptions: ${routeOptions}")
            
            // Convert to JSON string and back to DirectionsRoute
            val jsonString = gson.toJson(routeJson)
            val directionsRoute = gson.fromJson(jsonString, DirectionsRoute::class.java)
            
            // Set RouteOptions using copy method like MapWayPointFragment.kt line 589-604
            val finalRoute = directionsRoute.copy(routeOptions = routeOptions)
            
            Log.d(TAG, "DirectionsRoute created successfully with RouteOptions. Distance: ${finalRoute.distance}m")
            
            finalRoute
        } catch (e: Exception) {
            Log.e(TAG, "Error creating DirectionsRoute from data", e)
            null
        }
    }
    
    fun setMapView(mapView: com.trackasia.android.maps.MapView?) {
        this.mapView = mapView
    }
    
    fun setTrackAsiaMap(trackasiaMap: com.trackasia.android.maps.TrackAsiaMap?) {
        this.trackasiaMap = trackasiaMap
    }
    
    fun cleanup() {
        try {
            // Reset navigation state
            isNavigationActive = false
            currentRoute = null
            navigationMapRoute = null
            trackasiaNavigation = null
            mapView = null
            trackasiaMap = null
            Log.d(TAG, "Navigation resources cleaned up")
        } catch (e: Exception) {
            Log.e(TAG, "Error cleaning up navigation resources", e)
        }
    }
    
}