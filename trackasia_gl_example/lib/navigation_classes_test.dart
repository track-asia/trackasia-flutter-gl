import 'package:flutter/material.dart';
import 'package:trackasia_gl/trackasia_gl.dart';
import 'package:trackasia_gl_platform_interface/trackasia_gl_platform_interface.dart';

class NavigationClassesTest extends StatelessWidget {
  const NavigationClassesTest({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigation Classes Test'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _testNavigationOptions,
              child: const Text('Test NavigationOptions'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _testNavigationRoute,
              child: const Text('Test NavigationRoute'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _testNavigationEvent,
              child: const Text('Test NavigationEvent'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _testInstructions,
              child: const Text('Test Instructions'),
            ),
          ],
        ),
      ),
    );
  }

  void _testNavigationOptions() {
    try {
      final options = NavigationOptions(
        enableVoiceGuidance: true,
        enableRerouting: false,
        simulateRoute: true,
        profile: NavigationProfile.driving,
        language: 'en',
        units: DistanceUnits.metric,
      );
      print('NavigationOptions test PASSED: ${options.toMap()}');
    } catch (e) {
      print('NavigationOptions test FAILED: $e');
    }
  }

  void _testNavigationRoute() {
    try {
      final route = NavigationRoute(
        geometry: 'test_geometry_string',
        distance: 1500.0,
        duration: 300.0,
        waypoints: const [
          {'latitude': 10.7769, 'longitude': 106.7009},
          {'latitude': 10.7829, 'longitude': 106.6934},
        ],
      );
      print('NavigationRoute test PASSED: distance=${route.distance}m');
    } catch (e) {
      print('NavigationRoute test FAILED: $e');
    }
  }

  void _testNavigationEvent() {
    try {
      final event = NavigationEvent(
        type: NavigationEventType.routeProgress,
        data: const {'test': 'data'},
      );
      print('NavigationEvent test PASSED: ${event.type}');
    } catch (e) {
      print('NavigationEvent test FAILED: $e');
    }
  }

  void _testInstructions() {
    try {
      final voiceInstruction = VoiceInstruction(
        text: 'Turn right in 100 meters',
        distanceAlongGeometry: 100.0,
      );
      
      final bannerInstruction = BannerInstruction(
        primaryText: 'Turn right',
        secondaryText: 'onto Main Street',
        distanceAlongGeometry: 100.0,
        maneuverType: 'turn',
        maneuverModifier: 'right',
      );
      
      final routeProgress = RouteProgress(
        distanceRemaining: 1200.0,
        durationRemaining: 240.0,
        distanceTraveled: 300.0,
        fractionTraveled: 0.2,
        currentStepIndex: 1,
        currentLegIndex: 0,
      );
      
      print('Instructions test PASSED: Voice="${voiceInstruction.text}", Banner="${bannerInstruction.primaryText}", Progress=${routeProgress.fractionTraveled}');
    } catch (e) {
      print('Instructions test FAILED: $e');
    }
  }
}