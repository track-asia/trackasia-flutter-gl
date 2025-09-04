import 'package:trackasia_gl_platform_interface/trackasia_gl_platform_interface.dart';

void main() {
  // Test basic navigation classes
  print('Testing navigation classes...');
  
  try {
    // Test NavigationOptions
    final options = NavigationOptions();
    print('NavigationOptions created: ${options.runtimeType}');
    
    // Test NavigationProfile enum
    final profile = NavigationProfile.driving;
    print('NavigationProfile: $profile');
    
    // Test DistanceUnits enum
    final units = DistanceUnits.metric;
    print('DistanceUnits: $units');
    
    print('All navigation classes work!');
  } catch (e) {
    print('Error: $e');
  }
}