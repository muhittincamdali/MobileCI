Pod::Spec.new do |s|
  s.name             = 'MobileCI'
  s.version          = '1.0.0'
  s.summary          = 'CI/CD toolkit for mobile app development'
  s.description      = 'CI/CD toolkit for mobile app development. Built with modern Swift.'
  s.homepage         = 'https://github.com/muhittincamdali/MobileCI'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Muhittin Camdali' => 'contact@muhittincamdali.com' }
  s.source           = { :git => 'https://github.com/muhittincamdali/MobileCI.git', :tag => s.version.to_s }
  s.ios.deployment_target = '15.0'
  s.swift_versions = ['5.9', '5.10', '6.0']
  s.source_files = 'Sources/**/*.swift'
end
