Pod::Spec.new do |s|
  s.name     = 'TOAlertViewController'
  s.version  = '1.0.0'
  s.license  =  { :type => 'MIT', :file => 'LICENSE' }
  s.summary  = 'A modern looking modal popup UI component for iOS and iPadOS'
  s.homepage = 'https://github.com/TimOliver/TOAlertViewController'
  s.author   = 'Tim Oliver'
  s.source   = { :git => 'https://github.com/TimOliver/TOAlertViewController.git', :tag => s.version }
  s.platform = :ios, '11.0'
  s.source_files = 'TOAlertViewController/**/*.{h,m}'
  s.requires_arc = true
end
