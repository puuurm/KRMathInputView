#
# Be sure to run `pod lib lint KRMathInputView.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'KRMathInputView'
  s.version          = '0.5.1'
  s.summary          = 'A generic input view for math handwriting.'

  s.description      = <<-DESC
  `KRMathInputView` receives handwriting input and saves data as paths.
  By separating the parser that analyzes input data, `KRMathInputView` can be easily adopted into an existing project.
                       DESC

  s.homepage         = 'https://github.com/BridgeTheGap/KRMathInputView'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Woomin Park' => 'wmpark@knowre.com' }
  s.source           = { :git => 'https://github.com/BridgeTheGap/KRMathInputView.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.source_files = 'KRMathInputView/Classes/**/*'
  
  # s.resource_bundles = {
  #   'KRMathInputView' => ['KRMathInputView/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'KRStackView', '~> 0.4.1'
end
