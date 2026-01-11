#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'flida_auth_sdk_ios'
  s.version          = '0.0.1'
  s.summary          = 'An iOS implementation of the flida_auth_sdk plugin.'
  s.description      = <<-DESC
  An iOS implementation of the flida_auth_sdk plugin.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :type => 'BSD', :file => '../LICENSE' }
  s.author           = { 'Dev Flida Sdk' => 'email@example.com' }
  s.source           = { :path => '.' }  
  s.source_files = 'flida_auth_sdk_ios/Sources/**/*.swift'
  s.dependency 'Flutter'
  s.dependency 'FlidaIDSDK'
  s.platform = :ios, '13.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '6.1'
end
