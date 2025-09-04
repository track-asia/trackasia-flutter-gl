#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'trackasia_gl'
  s.version          = '2.0.3'
  s.summary          = 'A new Flutter plugin.'
  s.description      = <<-DESC
A new Flutter plugin.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'trackasia_gl/Sources/trackasia_gl/**/*'
  s.dependency 'Flutter'
  # When updating the dependency version,
  # make sure to also update the version in Package.swift.
  s.dependency 'Trackasia', '2.0.3'
  
  # TrackAsia Navigation dependencies
  s.dependency 'TrackAsiaNavigation', '~> 1.0.0'
  s.dependency 'TrackAsiaDirections', '~> 1.0.0'
  s.swift_version = '5.0'
  s.ios.deployment_target = '12.0'
end

