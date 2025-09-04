package com.trackasia.trackasiagl

import android.content.Context
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
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.Callback
import okhttp3.Call
import okhttp3.Response
import java.io.IOException


class NavigationMethodHandler(private val context: Context) : MethodChannel.MethodCallHandler {
    companion object {
        private const val TAG = "NavigationMethodHandler"
        private const val ACCESS_TOKEN = "pk.eyJ1IjoidHJhY2thc2lhIiwiYSI6ImNsczF6dGhtcjBhcWsya3BjZGQ4MXo3NjMifQ.4tJKLGNg_Y_k8E_xcPKvfA" // Default token, should be configurable
    }
    
    private var trackasiaNavigation: TrackAsiaNavigation? = null
    private var currentRoute: DirectionsRoute? = null
    private var navigationMapRoute: NavigationMapRoute? = null
    private var isNavigationActive = false

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "calculateRoute" -> calculateRoute(call, result)
            "startNavigation" -> startNavigation(call, result)
            "stopNavigation" -> stopNavigation(result)
            "getCurrentRoute" -> getCurrentRoute(result)
            "navigation#isActive" -> result.success(isNavigationActive)
            "isNavigationActive" -> result.success(isNavigationActive) // Keep backward compatibility
            else -> result.notImplemented()
        }
    }

    private fun calculateRoute(call: MethodCall, result: MethodChannel.Result) {
        try {
            val waypoints = call.argument<List<List<Double>>>("waypoints")
            if (waypoints == null || waypoints.size < 2) {
                result.error("INVALID_WAYPOINTS", "At least 2 waypoints are required", null)
                return
            }

            // Convert waypoints to Point objects
            val origin = Point.fromLngLat(waypoints[0][1], waypoints[0][0]) // lng, lat
            val destination = Point.fromLngLat(waypoints[1][1], waypoints[1][0]) // lng, lat
            
            Log.d(TAG, "Calculating route from ${waypoints[0]} to ${waypoints[1]}")

            // Build TrackAsia API URL
            val baseUrl = "https://api.track-asia.com/route/v1/car"
            val coordinates = "${origin.longitude()},${origin.latitude()};${destination.longitude()},${destination.latitude()}"
            val url = "$baseUrl/$coordinates?geometries=polyline6&steps=true&overview=full"
            
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
                        if (!response.isSuccessful) {
                            Log.e(TAG, "Route calculation failed with code: ${response.code}")
                            result.error("ROUTE_ERROR", "Route calculation failed with code: ${response.code}", null)
                            return
                        }
                        
                        response.body?.string()?.let { json ->
                            try {
                                val directionsResponse = DirectionsResponse.fromJson(json)
                                 if (directionsResponse.routes.isNotEmpty()) {
                                     val apiRoute = directionsResponse.routes[0]
                                     
                                     // Store the route for navigation
                                     currentRoute = apiRoute
                                     
                                     val routeMap = hashMapOf<String, Any?>(
                                         "geometry" to apiRoute.geometry,
                                         "distance" to apiRoute.distance,
                                         "duration" to apiRoute.duration,
                                         "waypoints" to waypoints
                                     )
                                    
                                    Log.d(TAG, "Route calculated successfully")
                                    result.success(routeMap)
                                } else {
                                    Log.e(TAG, "No routes found")
                                    result.error("NO_ROUTES", "No routes found", null)
                                }
                            } catch (e: Exception) {
                                Log.e(TAG, "Error parsing route response", e)
                                result.error("PARSE_ERROR", "Error parsing route response: ${e.message}", null)
                            }
                        } ?: run {
                            Log.e(TAG, "Empty response body")
                            result.error("EMPTY_RESPONSE", "Empty response body", null)
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

            // Build navigation launch options
            val options = NavigationLauncherOptions.builder()
                .directionsRoute(currentRoute!!)
                .shouldSimulateRoute(true) // Default to simulation for testing
                .build()

            // Start navigation using NavigationLauncher
            NavigationLauncher.startNavigation(context, options)
            isNavigationActive = true
            
            Log.d(TAG, "Navigation started successfully with route: ${currentRoute?.distance}m")
            result.success(true)
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

    fun cleanup() {
        try {
            // Reset navigation state
            isNavigationActive = false
            currentRoute = null
            navigationMapRoute = null
            trackasiaNavigation = null
            Log.d(TAG, "Navigation resources cleaned up")
        } catch (e: Exception) {
            Log.e(TAG, "Error cleaning up navigation resources", e)
        }
    }
}