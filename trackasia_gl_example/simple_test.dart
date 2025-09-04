import 'package:flutter/material.dart';
import 'package:trackasia_gl/trackasia_gl.dart';

void main() {
  runApp(const NavigationTestApp());
}

class NavigationTestApp extends StatelessWidget {
  const NavigationTestApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Navigation Test',
      home: const NavigationTestPage(),
    );
  }
}

class NavigationTestPage extends StatefulWidget {
  const NavigationTestPage({Key? key}) : super(key: key);

  @override
  State<NavigationTestPage> createState() => _NavigationTestPageState();
}

class _NavigationTestPageState extends State<NavigationTestPage> {
  final List<String> _testResults = [];

  @override
  void initState() {
    super.initState();
    _runTests();
  }

  void _runTests() {
    _addResult('=== BẮT ĐẦU KIỂM TRA NAVIGATION ===');
    
    // Test NavigationOptions
    _testNavigationOptions();
    
    // Test NavigationRoute
    _testNavigationRoute();
    
    // Test NavigationEvent
    _testNavigationEvent();
    
    // Test Instructions
    _testInstructions();
    
    _addResult('=== HOÀN THÀNH KIỂM TRA ===');
  }

  void _addResult(String result) {
    setState(() {
      _testResults.add(result);
    });
  }

  void _testNavigationOptions() {
    try {
      const options = NavigationOptions(
        enableVoiceGuidance: true,
        enableRerouting: true,
        simulateRoute: false,
        profile: NavigationProfile.driving,
        language: 'vi',
        units: DistanceUnits.metric,
      );
      
      final optionsMap = options.toMap();
      _addResult('✅ NavigationOptions: ${optionsMap.keys.length} properties');
      _addResult('   Voice: ${options.enableVoiceGuidance}');
      _addResult('   Profile: ${options.profile.name}');
      _addResult('   Language: ${options.language}');
    } catch (e) {
      _addResult('❌ NavigationOptions FAILED: $e');
    }
  }

  void _testNavigationRoute() {
    try {
      const route = NavigationRoute(
        geometry: 'sample_geometry_string',
        distance: 2500.0,
        duration: 420.0,
        waypoints: [
          {'latitude': 10.7769, 'longitude': 106.7009},
          {'latitude': 10.7829, 'longitude': 106.6934},
        ],
      );
      
      _addResult('✅ NavigationRoute: ${(route.distance/1000).toStringAsFixed(1)}km');
      _addResult('   Duration: ${(route.duration/60).toStringAsFixed(1)} phút');
      _addResult('   Waypoints: ${route.waypoints.length}');
    } catch (e) {
      _addResult('❌ NavigationRoute FAILED: $e');
    }
  }

  void _testNavigationEvent() {
    try {
      const event = NavigationEvent(
        type: NavigationEventType.navigationStarted,
        data: {'timestamp': 1234567890},
      );
      
      _addResult('✅ NavigationEvent: ${event.type.name}');
      
      final eventFromMap = NavigationEvent.fromMap({
        'type': 'arrival',
        'data': {'arrived': true},
      });
      _addResult('✅ Event fromMap: ${eventFromMap.type.name}');
    } catch (e) {
      _addResult('❌ NavigationEvent FAILED: $e');
    }
  }

  void _testInstructions() {
    try {
      const voiceInstruction = VoiceInstruction(
        text: 'Rẽ phải sau 200 mét',
        distanceAlongGeometry: 200.0,
      );
      
      const bannerInstruction = BannerInstruction(
        primaryText: 'Rẽ phải',
        secondaryText: 'vào đường Nguyễn Huệ',
        distanceAlongGeometry: 200.0,
        maneuverType: 'turn',
        maneuverModifier: 'right',
      );
      
      _addResult('✅ VoiceInstruction: "${voiceInstruction.text}"');
      _addResult('✅ BannerInstruction: "${bannerInstruction.primaryText}"');
    } catch (e) {
      _addResult('❌ Instructions FAILED: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigation Classes Test'),
        backgroundColor: Colors.blue,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _testResults.length,
        itemBuilder: (context, index) {
          final result = _testResults[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              result,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: result.startsWith('✅') 
                    ? Colors.green 
                    : result.startsWith('❌') 
                        ? Colors.red 
                        : Colors.black,
              ),
            ),
          );
        },
      ),
    );
  }
}