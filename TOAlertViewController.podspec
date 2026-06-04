Pod::Spec.new do |s|
  s.name     = 'TOAlertViewController'
  s.version  = '1.0.0'
  s.license  =  { :type => 'MIT', :file => 'LICENSE' }
  s.summary  = 'A modern looking modal popup UI component for iOS and iPadOS'
  s.homepage = 'https://github.com/TimOliver/TOAlertViewController'
  s.author   = 'Tim Oliver'
  s.source   = { :git => 'https://github.com/TimOliver/TOAlertViewController.git', :tag => s.version }
  s.platform = :ios, '15.0'
  s.source_files = 'TOAlertViewController/**/*.{h,m}'
  # `include/` holds symlinks to the public headers for Swift Package Manager only;
  # exclude it so CocoaPods doesn't see the headers twice.
  s.exclude_files = 'TOAlertViewController/include/**/*'
  s.requires_arc = true
  s.dependency 'TORoundedButton', '~> 2.1'
end
