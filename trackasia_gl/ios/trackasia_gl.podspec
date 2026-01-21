#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'trackasia_gl'
  s.version          = '2.0.3'
  s.summary          = 'TrackAsia GL Flutter Plugin with integrated navigation.'
  s.description      = <<-DESC
TrackAsia GL Flutter plugin with fully integrated navigation SDK.
Includes route calculation, turn-by-turn navigation UI, and voice guidance.
                       DESC
  s.homepage         = 'https://github.com/track-asia/trackasia-flutter-gl'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'TrackAsia' => 'support@track-asia.com' }
  s.source           = { :path => '.' }
  
  # Source files: Flutter plugin + embedded navigation SDK
  s.source_files = 'trackasia_gl/Sources/trackasia_gl/**/*.{swift,h,m}',
                   'Navigation/CoreNavigation/**/*.{swift,h,m}',
                   'Navigation/UI/**/*.{swift,h,m}'
  
  # Navigation resources (assets, localizations)
  # Note: Navigation/Resources includes all localizations - CoreNavigation/Resources is a subset
  s.resources = ['Navigation/Resources/**/*']
  
  s.dependency 'Flutter'
  
  # Map SDK
  s.dependency 'TrackAsia', '2.0.3'
  
  # Route calculation (MapboxDirections 2.x)
  s.dependency 'MapboxDirections', '~> 2.0'
  
  # Geometry calculations (used by navigation)
  s.dependency 'Turf', '~> 2.8'
  
  # NOTE: Solar is not available on CocoaPods (SPM-only)
  # Day/night style switching uses #if canImport(Solar) conditional
  
  s.swift_version = '5.0'
  s.ios.deployment_target = '12.0'
  
  # Framework settings for navigation
  s.frameworks = 'CoreLocation', 'MapKit', 'AVFoundation'
end
