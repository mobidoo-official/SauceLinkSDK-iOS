Pod::Spec.new do |s|
  s.name             = 'SauceLinkSDK'
  s.module_name      = 'SauceLinkSDK'
  s.version          = '1.0.0'
  s.summary          = 'SauceLink SDK for iOS'
  s.description      = <<-DESC
    SauceLink SDK는 iOS 앱에서 사용자 행동을 추적하고
    SauceLink 서버로 이벤트 데이터를 전송하는 SDK입니다.
    딥링크 기반 sLink 처리, 토큰 인증, 이벤트 트래킹 기능을 제공합니다.
  DESC

  s.homepage         = 'https://saucelive.net'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'SauceLive' => 'dev@saucelive.net' }

  # S3 기반 배포 URL
  s.source           = { :http => 'https://sdk.saucelink.im/iOS/SauceLinkSDK-1.0.0.zip' }

  s.ios.deployment_target = '14.0'
  s.swift_version = '5.5'

  # XCFramework 기반 배포
  s.vendored_frameworks = 'SauceLinkSDK.xcframework'

  s.frameworks = 'Foundation', 'UIKit'
end
