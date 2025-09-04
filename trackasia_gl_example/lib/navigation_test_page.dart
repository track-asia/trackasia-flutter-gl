import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:trackasia_gl/trackasia_gl.dart';
import 'page.dart';

class NavigationTestPage extends ExamplePage {
  const NavigationTestPage({super.key}) : super(const Icon(Icons.bug_report), 'Navigation Test');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigation Test'),
      ),
      body: const NavigationTestWidget(),
    );
  }
}

class NavigationTestWidget extends StatefulWidget {
  const NavigationTestWidget({super.key});

  @override
  State<NavigationTestWidget> createState() => _NavigationTestWidgetState();
}

class _NavigationTestWidgetState extends State<NavigationTestWidget> {
  static const MethodChannel _channel = MethodChannel('plugins.flutter.io/trackasia_gl');
  
  final List<String> _testResults = [];
  bool _isRunningTests = false;
  Map<String, dynamic>? _lastCalculatedRoute;
  
  void _addTestResult(String result) {
    setState(() {
      _testResults.add('${DateTime.now().toString().substring(11, 19)}: $result');
    });
  }
  
  void _clearResults() {
    setState(() {
      _testResults.clear();
    });
  }
  
  Future<void> _testRouteCalculation() async {
    _addTestResult('🧪 Testing route calculation...');
    
    try {
      final waypoints = [
        [10.8231, 106.6297], // Ho Chi Minh City
        [16.0544, 108.2022], // Da Nang
      ];
      
      final result = await _channel.invokeMethod('navigation#calculateRoute', {
        'waypoints': waypoints,
        'profile': 'driving',
      });
      
      if (result != null && result is Map) {
        _lastCalculatedRoute = Map<String, dynamic>.from(result);
        _addTestResult('✅ Route calculation successful!');
        _addTestResult('   Distance: ${result['distance']}m');
        _addTestResult('   Duration: ${result['duration']}s');
        if (result['geometry'] != null) {
          final geometry = result['geometry'].toString();
          _addTestResult('   Geometry: ${geometry.length > 50 ? geometry.substring(0, 50) + '...' : geometry}');
        }
      } else {
        _addTestResult('❌ Route calculation failed: null or invalid result');
      }
    } catch (e) {
      _addTestResult('❌ Route calculation error: $e');
    }
  }
  
  Future<void> _testNavigationStart() async {
    _addTestResult('🧪 Testing navigation start...');
    
    if (_lastCalculatedRoute == null) {
      _addTestResult('❌ Cannot start navigation: no route calculated');
      _addTestResult('   Please run route calculation test first');
      return;
    }
    
    try {
      final result = await _channel.invokeMethod('navigation#start', {
        'route': _lastCalculatedRoute,
      });
      
      if (result == true) {
        _addTestResult('✅ Navigation started successfully!');
        
        // Check if navigation is active
        await Future.delayed(const Duration(milliseconds: 500));
        final isActive = await _channel.invokeMethod('navigation#isActive');
        _addTestResult('   Navigation active: $isActive');
        
        // Get current progress
        final progress = await _channel.invokeMethod('navigation#getProgress');
        if (progress != null && progress is Map) {
          _addTestResult('   Distance remaining: ${progress['distanceRemaining']}m');
          _addTestResult('   Duration remaining: ${progress['durationRemaining']}s');
          _addTestResult('   Fraction traveled: ${progress['fractionTraveled']}');
        }
      } else {
        _addTestResult('❌ Navigation start failed: $result');
      }
    } catch (e) {
      _addTestResult('❌ Navigation start error: $e');
    }
  }
  
  Future<void> _testNavigationStatus() async {
    _addTestResult('🧪 Testing navigation status...');
    
    try {
      final isActive = await _channel.invokeMethod('navigation#isActive');
      _addTestResult('✅ Navigation status check successful!');
      _addTestResult('   Navigation active: $isActive');
      
      if (isActive == true) {
        final progress = await _channel.invokeMethod('navigation#getProgress');
        if (progress != null && progress is Map) {
          _addTestResult('   Current progress available:');
          _addTestResult('     Distance remaining: ${progress['distanceRemaining']}m');
          _addTestResult('     Duration remaining: ${progress['durationRemaining']}s');
          _addTestResult('     Fraction traveled: ${progress['fractionTraveled']}');
          _addTestResult('     Current step: ${progress['currentStepIndex']}');
          _addTestResult('     Current leg: ${progress['currentLegIndex']}');
        }
      }
    } catch (e) {
      _addTestResult('❌ Navigation status error: $e');
    }
  }
  
  Future<void> _testNavigationStop() async {
    _addTestResult('🧪 Testing navigation stop...');
    
    try {
      await _channel.invokeMethod('navigation#stop');
      
      // Check if navigation is still active
      await Future.delayed(const Duration(milliseconds: 500));
      final isActive = await _channel.invokeMethod('navigation#isActive');
      
      if (isActive == false) {
        _addTestResult('✅ Navigation stopped successfully!');
        _addTestResult('   Navigation active: $isActive');
      } else {
        _addTestResult('❌ Navigation stop failed - still active: $isActive');
      }
    } catch (e) {
      _addTestResult('❌ Navigation stop error: $e');
    }
  }
  
  Future<void> _testNavigationProfiles() async {
    _addTestResult('🧪 Testing different navigation profiles...');
    
    final waypoints = [
      [10.8231, 106.6297], // Ho Chi Minh City
      [10.7769, 106.7009], // Tan Son Nhat Airport
    ];
    
    final profiles = ['driving', 'walking', 'cycling'];
    
    for (final profile in profiles) {
      try {
        _addTestResult('   Testing $profile profile...');
        
        final result = await _channel.invokeMethod('navigation#calculateRoute', {
          'waypoints': waypoints,
          'profile': profile,
        });
        
        if (result != null && result is Map) {
          _addTestResult('   ✅ $profile: ${result['distance']}m, ${result['duration']}s');
        } else {
          _addTestResult('   ❌ $profile: failed to calculate route');
        }
      } catch (e) {
        _addTestResult('   ❌ $profile: error - $e');
      }
    }
  }
  
  Future<void> _testPauseResume() async {
    _addTestResult('🧪 Testing navigation pause/resume...');
    
    try {
      // Pause navigation
      await _channel.invokeMethod('navigation#pause');
      _addTestResult('   ✅ Navigation paused');
      
      // Wait a bit
      await Future.delayed(const Duration(seconds: 1));
      
      // Resume navigation
      await _channel.invokeMethod('navigation#resume');
      _addTestResult('   ✅ Navigation resumed');
    } catch (e) {
      _addTestResult('   ❌ Pause/resume error: $e');
    }
  }
  
  Future<void> _runAllTests() async {
    if (_isRunningTests) return;
    
    setState(() {
      _isRunningTests = true;
    });
    
    _clearResults();
    _addTestResult('🚀 Starting TrackAsia Navigation Tests...');
    _addTestResult('=' * 30);
    
    try {
      // Test 1: Route calculation
      await _testRouteCalculation();
      await Future.delayed(const Duration(seconds: 1));
      
      if (_lastCalculatedRoute != null) {
        // Test 2: Navigation start
        await _testNavigationStart();
        await Future.delayed(const Duration(seconds: 1));
        
        // Test 3: Navigation status
        await _testNavigationStatus();
        await Future.delayed(const Duration(seconds: 1));
        
        // Test 4: Pause/resume
        await _testPauseResume();
        await Future.delayed(const Duration(seconds: 1));
        
        // Test 5: Navigation stop
        await _testNavigationStop();
        await Future.delayed(const Duration(seconds: 1));
      }
      
      // Test 6: Different profiles
      await _testNavigationProfiles();
      
      _addTestResult('=' * 30);
      _addTestResult('🎉 All navigation tests completed!');
    } catch (e) {
      _addTestResult('❌ Test suite error: $e');
    } finally {
      setState(() {
        _isRunningTests = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Control buttons
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _isRunningTests ? null : _runAllTests,
                    child: Text(_isRunningTests ? 'Running...' : 'Run All Tests'),
                  ),
                  ElevatedButton(
                    onPressed: _clearResults,
                    child: const Text('Clear Results'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _isRunningTests ? null : _testRouteCalculation,
                    child: const Text('Test Route'),
                  ),
                  ElevatedButton(
                    onPressed: _isRunningTests ? null : _testNavigationStart,
                    child: const Text('Test Start'),
                  ),
                  ElevatedButton(
                    onPressed: _isRunningTests ? null : _testNavigationStatus,
                    child: const Text('Test Status'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _isRunningTests ? null : _testNavigationStop,
                    child: const Text('Test Stop'),
                  ),
                  ElevatedButton(
                    onPressed: _isRunningTests ? null : _testNavigationProfiles,
                    child: const Text('Test Profiles'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(),
        // Test results
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Test Results (${_testResults.length} entries):',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ListView.builder(
                      itemCount: _testResults.length,
                      itemBuilder: (context, index) {
                        final result = _testResults[index];
                        Color textColor = Colors.black;
                        
                        if (result.contains('✅')) {
                          textColor = Colors.green;
                        } else if (result.contains('❌')) {
                          textColor = Colors.red;
                        } else if (result.contains('🧪')) {
                          textColor = Colors.blue;
                        }
                        
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          child: Text(
                            result,
                            style: TextStyle(
                              color: textColor,
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}