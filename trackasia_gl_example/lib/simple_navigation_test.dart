import 'package:flutter/material.dart';
import 'package:trackasia_gl/trackasia_gl.dart';

class SimpleNavigationTest extends StatefulWidget {
  const SimpleNavigationTest({Key? key}) : super(key: key);

  @override
  State<SimpleNavigationTest> createState() => _SimpleNavigationTestState();
}

class _SimpleNavigationTestState extends State<SimpleNavigationTest> {
  TrackAsiaMapController? mapController;
  String _statusText = 'Ready to test navigation classes';

  // Test coordinates (Ho Chi Minh City area)
  final LatLng _origin = const LatLng(10.7769, 106.7009);
  final LatLng _destination = const LatLng(10.7829, 106.6934);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigation Classes Test'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          // Status panel
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status: $_statusText',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Origin: ${_origin.latitude.toStringAsFixed(4)}, ${_origin.longitude.toStringAsFixed(4)}',
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  'Destination: ${_destination.latitude.toStringAsFixed(4)}, ${_destination.longitude.toStringAsFixed(4)}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          // Control buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _testNavigationOptions,
                      child: const Text('Test Options'),
                    ),
                    ElevatedButton(
                      onPressed: _testNavigationRoute,
                      child: const Text('Test Route'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _testNavigationEvent,
                      child: const Text('Test Event'),
                    ),
                    ElevatedButton(
                      onPressed: _testInstructions,
                      child: const Text('Test Instructions'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Map
          Expanded(
            child: TrackAsiaMap(
              styleString: 'https://tiles.track-asia.com/tiles/v3/style-streets.json?key=public',
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _origin,
                zoom: 14.0,
              ),
              onStyleLoadedCallback: _onStyleLoaded,
            ),
          ),
        ],
      ),
    );
  }

  void _onMapCreated(TrackAsiaMapController controller) {
    mapController = controller;
    setState(() {
      _statusText = 'Map created successfully';
    });
  }

  void _onStyleLoaded() {
    setState(() {
      _statusText = 'Map style loaded - Ready for navigation tests';
    });
    _addMarkers();
  }

  void _addMarkers() async {
    if (mapController == null) return;

    try {
      // Add origin marker
      await mapController!.addSymbol(SymbolOptions(
        geometry: _origin,
        iconImage: 'marker-15',
        iconSize: 2.0,
        textField: 'Start',
        textOffset: const Offset(0, 2),
      ));

      // Add destination marker
      await mapController!.addSymbol(SymbolOptions(
        geometry: _destination,
        iconImage: 'marker-15',
        iconSize: 2.0,
        textField: 'End',
        textOffset: const Offset(0, 2),
      ));

      setState(() {
        _statusText = 'Markers added - Navigation classes ready to test';
      });
    } catch (e) {
      setState(() {
        _statusText = 'Error adding markers: $e';
      });
    }
  }

  void _testNavigationOptions() {
    try {
      // Test creating navigation options
      const options = NavigationOptions(
        enableVoiceGuidance: true,
        enableRerouting: false,
        simulateRoute: true,
        profile: NavigationProfile.driving,
        language: 'en',
        units: DistanceUnits.metric,
      );

      final optionsMap = options.toMap();
      
      setState(() {
        _statusText = 'NavigationOptions test PASSED: ${optionsMap.keys.length} properties created';
      });
    } catch (e) {
      setState(() {
        _statusText = 'NavigationOptions test FAILED: $e';
      });
    }
  }

  void _testNavigationRoute() {
    try {
      // Test creating navigation route
      const route = NavigationRoute(
        geometry: 'test_geometry_string',
        distance: 1500.0,
        duration: 300.0,
        waypoints: [
          {'latitude': 10.7769, 'longitude': 106.7009},
          {'latitude': 10.7829, 'longitude': 106.6934},
        ],
      );

      setState(() {
        _statusText = 'NavigationRoute test PASSED: distance=${route.distance}m, duration=${route.duration}s';
      });
    } catch (e) {
      setState(() {
        _statusText = 'NavigationRoute test FAILED: $e';
      });
    }
  }

  void _testNavigationEvent() {
    try {
      // Test creating navigation event
      const event = NavigationEvent(
        type: NavigationEventType.routeProgress,
        data: {'test': 'data'},
      );

      // Test creating from map
      final eventFromMap = NavigationEvent.fromMap({
        'type': 'arrival',
        'data': {'arrived': true},
      });

      setState(() {
        _statusText = 'NavigationEvent test PASSED: ${event.type.name}, fromMap: ${eventFromMap.type.name}';
      });
    } catch (e) {
      setState(() {
        _statusText = 'NavigationEvent test FAILED: $e';
      });
    }
  }

  void _testInstructions() {
    try {
      // Test VoiceInstruction
      const voiceInstruction = VoiceInstruction(
        text: 'Turn right in 100 meters',
        distanceAlongGeometry: 100.0,
      );

      // Test BannerInstruction
      const bannerInstruction = BannerInstruction(
        primaryText: 'Turn right',
        secondaryText: 'onto Main Street',
        distanceAlongGeometry: 100.0,
        maneuverType: 'turn',
        maneuverModifier: 'right',
      );

      // Test RouteProgress
      const routeProgress = RouteProgress(
        distanceRemaining: 1200.0,
        durationRemaining: 240.0,
        distanceTraveled: 300.0,
        fractionTraveled: 0.2,
        currentStepIndex: 1,
        currentLegIndex: 0,
      );

      setState(() {
        _statusText = 'Instructions test PASSED: Voice="${voiceInstruction.text}", Banner="${bannerInstruction.primaryText}", Progress=${routeProgress.fractionTraveled}';
      });
    } catch (e) {
      setState(() {
        _statusText = 'Instructions test FAILED: $e';
      });
    }
  }
}