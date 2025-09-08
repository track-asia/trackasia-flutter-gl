# TrackAsia Navigation - Android Native Implementation

## Overview

The Android native implementation of TrackAsia Navigation is built using Kotlin and integrates with the TrackAsia Navigation SDK for Android. The main component is `NavigationMethodHandler.kt` which handles all Flutter method calls and manages navigation functionality.

## Core Components

### NavigationMethodHandler.kt

**Location**: `android/src/main/java/com/trackasia/trackasiagl/NavigationMethodHandler.kt`

**Purpose**: Central handler for all navigation-related method calls from Flutter

#### Class Structure

```kotlin
class NavigationMethodHandler(private val context: Context) : MethodChannel.MethodCallHandler {
    companion object {
        private const val TAG = "NavigationMethodHandler"
        private const val ACCESS_TOKEN = "public_key" // Default token, should be configurable
    }
    
    // Core navigation components
    private var trackasiaNavigation: TrackAsiaNavigation? = null
    private var currentRoute: DirectionsRoute? = null
    private var navigationMapRoute: NavigationMapRoute? = null
    private var isNavigationActive = false
    private var mapView: com.trackasia.android.maps.MapView? = null
    private var trackasiaMap: com.trackasia.android.maps.TrackAsiaMap? = null
}
```

#### Key Dependencies

```kotlin
// Navigation Core
import com.trackasia.navigation.core.navigation.TrackAsiaNavigation
import com.trackasia.navigation.core.models.DirectionsResponse
import com.trackasia.navigation.core.models.DirectionsRoute
import com.trackasia.navigation.core.models.RouteOptions

// Navigation UI
import com.trackasia.navigation.android.navigation.ui.v5.NavigationLauncher
import com.trackasia.navigation.android.navigation.ui.v5.NavigationLauncherOptions
import com.trackasia.navigation.android.navigation.ui.v5.route.NavigationMapRoute

// Map Components
import com.trackasia.android.maps.MapView
import com.trackasia.android.maps.TrackAsiaMap
import com.trackasia.geojson.Point

// HTTP Client
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.Callback
```

## Method Call Handling

### onMethodCall Implementation

```kotlin
override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
        "calculateRoute" -> calculateRoute(call, result)
        "startNavigation" -> startNavigation(call, result)
        "stopNavigation" -> stopNavigation(result)
        "getCurrentRoute" -> getCurrentRoute(result)
        "addNavigationRoute" -> addNavigationRoute(call, result)
        "addNavigationRoutes" -> addNavigationRoutes(call, result)
        "removeNavigationRoute" -> removeNavigationRoute(call, result)
        "clearNavigationRoutes" -> clearNavigationRoutes(result)
        "setRouteVisibility" -> setRouteVisibility(call, result)
        "fitCameraToRoutes" -> fitCameraToRoutes(call, result)
        else -> result.notImplemented()
    }
}
```

## Core Functionality

### 1. Route Calculation

#### calculateRoute Method

```kotlin
private fun calculateRoute(call: MethodCall, result: MethodChannel.Result) {
    try {
        // Extract parameters from Flutter call
        val waypoints = call.argument<List<Map<String, Double>>>("waypoints")
        val profile = call.argument<String>("profile") ?: "driving"
        val language = call.argument<String>("language") ?: "en"
        val alternatives = call.argument<Boolean>("alternatives") ?: false
        
        // Validate waypoints
        if (waypoints == null || waypoints.size < 2) {
            result.error("INVALID_WAYPOINTS", "At least 2 waypoints required", null)
            return
        }
        
        // Convert Flutter waypoints to TrackAsia Points
        val points = waypoints.mapNotNull { waypoint ->
            val lat = waypoint["latitude"]
            val lng = waypoint["longitude"]
            if (lat != null && lng != null) {
                Point.fromLngLat(lng, lat)
            } else null
        }
        
        // Build API request URL
        val baseUrl = "https://maps.track-asia.com/route/v1/$profile"
        val coordinates = points.joinToString(";") { "${it.longitude()},${it.latitude()}" }
        val url = "$baseUrl/$coordinates.json?geometries=polyline6&steps=true&overview=full&alternatives=$alternatives&language=$language&key=$ACCESS_TOKEN"
        
        // Make HTTP request
        val client = OkHttpClient()
        val request = Request.Builder()
            .url(url)
            .header("User-Agent", "TrackAsia Flutter Navigation SDK")
            .build()
            
        client.newCall(request).enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                Handler(Looper.getMainLooper()).post {
                    result.error("NETWORK_ERROR", "Failed to calculate route: ${e.message}", null)
                }
            }
            
            override fun onResponse(call: Call, response: Response) {
                response.use {
                    if (!response.isSuccessful) {
                        Handler(Looper.getMainLooper()).post {
                            result.error("API_ERROR", "Route calculation failed: ${response.code}", null)
                        }
                        return
                    }
                    
                    val responseBody = response.body?.string()
                    if (responseBody != null) {
                        processRouteResponse(responseBody, result)
                    }
                }
            }
        })
    } catch (e: Exception) {
        result.error("CALCULATION_ERROR", "Error calculating route: ${e.message}", null)
    }
}
```

#### Route Response Processing

```kotlin
private fun processRouteResponse(responseJson: String, result: MethodChannel.Result) {
    try {
        val directionsResponse = DirectionsResponse.fromJson(responseJson)
        
        if (directionsResponse.routes.isEmpty()) {
            result.error("NO_ROUTES", "No routes found", null)
            return
        }
        
        val route = directionsResponse.routes.first()
        currentRoute = route
        
        // Display route on map if NavigationMapRoute is available
        navigationMapRoute?.let { navMapRoute ->
            Handler(Looper.getMainLooper()).post {
                navMapRoute.removeRoute()
                navMapRoute.addRoute(route)
            }
        }
        
        // Return route data to Flutter
        val routeData = mapOf(
            "geometry" to route.geometry,
            "distance" to route.distance,
            "duration" to route.duration,
            "legs" to route.legs.map { leg ->
                mapOf(
                    "distance" to leg.distance,
                    "duration" to leg.duration,
                    "steps" to leg.steps?.map { step ->
                        mapOf(
                            "instruction" to step.maneuver.instruction,
                            "distance" to step.distance,
                            "duration" to step.duration
                        )
                    } ?: emptyList()
                )
            }
        )
        
        result.success(routeData)
    } catch (e: Exception) {
        result.error("PROCESSING_ERROR", "Error processing route response: ${e.message}", null)
    }
}
```

### 2. Navigation Control

#### startNavigation Method

```kotlin
private fun startNavigation(call: MethodCall, result: MethodChannel.Result) {
    try {
        if (currentRoute == null) {
            result.error("NO_ROUTE", "No route available for navigation", null)
            return
        }
        
        val simulate = call.argument<Boolean>("simulate") ?: false
        val voiceInstructions = call.argument<Boolean>("voiceInstructions") ?: true
        val bannerInstructions = call.argument<Boolean>("bannerInstructions") ?: true
        
        // Create navigation options
        val options = NavigationLauncherOptions.builder()
            .directionsRoute(currentRoute!!)
            .shouldSimulateRoute(simulate)
            .build()
        
        // Launch navigation activity
        NavigationLauncher.startNavigation(context as Activity, options)
        
        isNavigationActive = true
        result.success(mapOf("success" to true, "navigationStarted" to true))
        
    } catch (e: Exception) {
        result.error("NAVIGATION_START_ERROR", "Failed to start navigation: ${e.message}", null)
    }
}
```

#### stopNavigation Method

```kotlin
private fun stopNavigation(result: MethodChannel.Result) {
    try {
        // Stop TrackAsia Navigation if active
        trackasiaNavigation?.stopNavigation()
        
        isNavigationActive = false
        currentRoute = null
        
        result.success(mapOf("success" to true, "navigationStopped" to true))
        
    } catch (e: Exception) {
        result.error("NAVIGATION_STOP_ERROR", "Failed to stop navigation: ${e.message}", null)
    }
}
```

### 3. Route Display Management

#### addNavigationRoute Method

```kotlin
private fun addNavigationRoute(call: MethodCall, result: MethodChannel.Result) {
    try {
        val routeData = call.argument<Map<String, Any>>("route")
        val isPrimary = call.argument<Boolean>("isPrimary") ?: true
        val routeId = call.argument<String>("routeId") ?: UUID.randomUUID().toString()
        
        if (routeData == null) {
            result.error("INVALID_ROUTE", "Route data is required", null)
            return
        }
        
        // Extract route information
        val geometry = routeData["geometry"] as? String
        val distance = routeData["distance"] as? Double ?: 0.0
        val duration = routeData["duration"] as? Double ?: 0.0
        val waypoints = routeData["waypoints"] as? List<Map<String, Any>> ?: emptyList()
        
        if (geometry.isNullOrBlank()) {
            result.error("INVALID_GEOMETRY", "Route geometry is required", null)
            return
        }
        
        // Create DirectionsRoute from data
        val directionsRoute = createDirectionsRouteFromData(geometry, distance, duration, waypoints)
        
        if (directionsRoute == null) {
            result.error("ROUTE_CREATION_ERROR", "Failed to create DirectionsRoute", null)
            return
        }
        
        // Ensure we're on the UI thread for map operations
        Handler(Looper.getMainLooper()).post {
            try {
                if (navigationMapRoute == null && mapView != null && trackasiaMap != null) {
                    navigationMapRoute = NavigationMapRoute(null, mapView!!, trackasiaMap!!)
                }
                
                navigationMapRoute?.let { navMapRoute ->
                    if (isPrimary) {
                        // For primary route, replace existing route
                        navMapRoute.removeRoute()
                        navMapRoute.addRoute(directionsRoute)
                        currentRoute = directionsRoute
                    } else {
                        // For alternative routes, add without replacing
                        navMapRoute.addRoutes(listOf(directionsRoute))
                    }
                    
                    Log.d(TAG, "Route added successfully: $routeId (primary: $isPrimary)")
                    result.success(mapOf(
                        "routeId" to routeId,
                        "isPrimary" to isPrimary,
                        "success" to true
                    ))
                } ?: run {
                    result.error("MAP_NOT_READY", "Map is not ready for route display", null)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error adding route to map", e)
                result.error("ROUTE_DISPLAY_ERROR", "Error displaying route: ${e.message}", null)
            }
        }
    } catch (e: Exception) {
        Log.e(TAG, "Error in addNavigationRoute", e)
        result.error("ADD_ROUTE_ERROR", "Error adding navigation route: ${e.message}", null)
    }
}
```

#### removeNavigationRoute Method

```kotlin
private fun removeNavigationRoute(call: MethodCall, result: MethodChannel.Result) {
    try {
        val routeId = call.argument<String>("routeId")
        
        if (routeId.isNullOrBlank()) {
            result.error("INVALID_ROUTE_ID", "Route ID is required", null)
            return
        }
        
        Handler(Looper.getMainLooper()).post {
            try {
                navigationMapRoute?.removeRoute()
                
                // If this was the current route, clear it
                if (currentRoute != null) {
                    currentRoute = null
                }
                
                Log.d(TAG, "Route removed: $routeId")
                result.success(mapOf("routeId" to routeId, "success" to true))
            } catch (e: Exception) {
                Log.e(TAG, "Error removing route", e)
                result.error("REMOVE_ROUTE_ERROR", "Error removing route: ${e.message}", null)
            }
        }
    } catch (e: Exception) {
        result.error("REMOVE_ROUTE_ERROR", "Error removing navigation route: ${e.message}", null)
    }
}
```

### 4. Utility Methods

#### createDirectionsRouteFromData

```kotlin
private fun createDirectionsRouteFromData(
    geometry: String,
    distance: Double,
    duration: Double,
    waypoints: List<Map<String, Any>>
): DirectionsRoute? {
    return try {
        // Validation
        if (geometry.isBlank() || waypoints.size < 2) {
            Log.e(TAG, "Invalid route data: geometry or waypoints")
            return null
        }
        
        val gson = Gson()
        
        // Convert waypoints to proper format
        val waypointsList = waypoints.mapNotNull { waypoint ->
            val latitude = waypoint["latitude"] as? Double
            val longitude = waypoint["longitude"] as? Double
            
            if (latitude != null && longitude != null) {
                mapOf(
                    "location" to listOf(longitude, latitude),
                    "name" to ""
                )
            } else {
                Log.w(TAG, "Invalid waypoint format: $waypoint")
                null
            }
        }
        
        if (waypointsList.size < 2) {
            Log.e(TAG, "Insufficient valid waypoints: ${waypointsList.size}")
            return null
        }
        
        // Create legs array
        val legsCount = waypointsList.size - 1
        val legDistance = distance / legsCount
        val legDuration = duration / legsCount
        
        val legs = (0 until legsCount).map {
            mapOf(
                "distance" to legDistance,
                "duration" to legDuration,
                "weight" to legDistance,
                "summary" to "",
                "steps" to emptyList<Any>()
            )
        }
        
        // Create DirectionsRoute JSON structure
        val routeJson = mapOf(
            "geometry" to geometry,
            "distance" to distance,
            "duration" to duration,
            "weight" to distance,
            "weight_name" to "routability",
            "legs" to legs,
            "waypoints" to waypointsList
        )
        
        // Convert to DirectionsRoute object
        val jsonString = gson.toJson(routeJson)
        gson.fromJson(jsonString, DirectionsRoute::class.java)
        
    } catch (e: Exception) {
        Log.e(TAG, "Error creating DirectionsRoute", e)
        null
    }
}
```

## Lifecycle Management

### Initialization

```kotlin
fun setMapView(mapView: com.trackasia.android.maps.MapView?) {
    this.mapView = mapView
}

fun setTrackAsiaMap(trackasiaMap: com.trackasia.android.maps.TrackAsiaMap?) {
    this.trackasiaMap = trackasiaMap
}
```

### Cleanup

```kotlin
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
```

## Error Handling

### Common Error Types

1. **INVALID_WAYPOINTS**: Insufficient or invalid waypoint data
2. **NETWORK_ERROR**: HTTP request failures
3. **API_ERROR**: TrackAsia API errors
4. **NO_ROUTES**: No routes found in response
5. **NAVIGATION_START_ERROR**: Failed to start navigation
6. **MAP_NOT_READY**: Map components not initialized
7. **ROUTE_DISPLAY_ERROR**: Failed to display route on map

### Error Response Format

```kotlin
result.error(errorCode, errorMessage, errorDetails)
```

## Threading Considerations

- All map operations must be performed on the UI thread
- HTTP requests are performed on background threads
- Use `Handler(Looper.getMainLooper()).post {}` for UI thread operations
- Proper exception handling in both UI and background threads

## Integration Points

### Flutter Plugin Integration

```kotlin
// In TrackAsiaMapController.java
private NavigationMethodHandler navigationMethodHandler;

public void setNavigationMethodHandler(NavigationMethodHandler handler) {
    this.navigationMethodHandler = handler;
    handler.setMapView(mapView);
    handler.setTrackAsiaMap(trackasiaMap);
}
```

### Method Channel Registration

```kotlin
// In plugin registration
val navigationChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "trackasia_navigation")
val navigationHandler = NavigationMethodHandler(context)
navigationChannel.setMethodCallHandler(navigationHandler)
```

## Performance Considerations

1. **Route Caching**: Cache calculated routes to avoid redundant API calls
2. **Memory Management**: Properly clean up navigation resources
3. **UI Thread**: Ensure map operations are on UI thread
4. **Network Optimization**: Use appropriate timeouts and retry mechanisms
5. **Polyline Optimization**: Use appropriate polyline precision for performance

## Security Best Practices

1. **API Key Management**: Store API keys securely
2. **Input Validation**: Validate all input parameters
3. **HTTPS**: Use secure connections for API calls
4. **Permission Handling**: Proper location permission management
5. **Error Information**: Don't expose sensitive information in error messages

This Android implementation provides a robust foundation for navigation functionality with proper error handling, threading, and integration with the TrackAsia Navigation SDK.