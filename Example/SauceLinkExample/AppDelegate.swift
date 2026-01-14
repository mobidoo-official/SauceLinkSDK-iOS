import UIKit
import SauceLinkSDK

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    // SDK 초기화 상태 저장 (전역 접근용)
    static var sdkInitialized: Bool = false
    static var sdkAuthSuccess: Bool = false
    static var sdkAuthStatusCode: Int = 0

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // 저장된 설정으로 SDK 초기화
        initializeSDK()
        
        return true
    }
    
    func initializeSDK() {
        let configManager = ConfigManager.shared
        
        print("\n" + String(repeating: "=", count: 60))
        print("🔍 ConfigManager 상태 확인")
        print("   저장된 Partner ID: '\(configManager.partnerUniqueId)'")
        print("   저장된 Token: '\(configManager.token)'")
        print("   isConfigured: \(configManager.isConfigured)")
        print(String(repeating: "-", count: 60))
        
        // 설정이 저장되어 있지 않으면 SDK 초기화 스킵
        guard configManager.isConfigured else {
            print("⚠️ SDK 설정이 없습니다. Settings에서 Partner ID와 Token을 입력해주세요.")
            print(String(repeating: "=", count: 60) + "\n")
            return
        }

        let partnerUniqueId = configManager.partnerUniqueId
        let token = configManager.token

        print("🔄 SDK 초기화 중...")
        print("   사용할 Partner ID: \(partnerUniqueId)")
        print("   사용할 Token: \(token)")
        print("   Environment: \(configManager.environmentDisplayName)")
        print(String(repeating: "=", count: 60) + "\n")
        
        // Android 가이드 스타일의 configure 메서드 사용
        SauceLink.shared.configure(
            partnerUniqueId: partnerUniqueId,
            sdkToken: token,
            environment: configManager.environment
        ) { result in
            switch result {
            case .success:
                print("✅ SDK 초기화 성공 (토큰 인증: 200 OK)")
                
                // 저장된 sLink가 있으면 적용
                let savedSlink = configManager.slink
                let savedSlinkT = configManager.slinkT
                if !savedSlink.isEmpty {
                    print("📦 로컬 저장된 sLink 적용: \(savedSlink)")
                    SauceLink.shared.updateSlink(savedSlink, savedSlinkT.isEmpty ? nil : savedSlinkT)
                }
                
                // 메인 스레드에서 상태 저장 및 notification 발송
                DispatchQueue.main.async {
                    AppDelegate.sdkInitialized = true
                    AppDelegate.sdkAuthSuccess = true
                    AppDelegate.sdkAuthStatusCode = 200
                    
                    print("📤 [AppDelegate] SDKInitialized notification 발송 (success=true, statusCode=200)")
                    NotificationCenter.default.post(
                        name: NSNotification.Name("SDKInitialized"),
                        object: nil,
                        userInfo: ["success": true, "statusCode": 200]
                    )
                }
                
            case .failure(let error):
                print("❌ SDK 초기화 실패: \(error.localizedDescription)")
                
                // 에러에서 실제 status code 추출
                let statusCode = (error as NSError).code
                
                // 메인 스레드에서 상태 저장 및 notification 발송
                DispatchQueue.main.async {
                    AppDelegate.sdkInitialized = true
                    AppDelegate.sdkAuthSuccess = false
                    AppDelegate.sdkAuthStatusCode = statusCode
                    
                    print("📤 [AppDelegate] SDKInitialized notification 발송 (success=false, statusCode=\(statusCode))")
                    NotificationCenter.default.post(
                        name: NSNotification.Name("SDKInitialized"),
                        object: nil,
                        userInfo: ["success": false, "statusCode": statusCode]
                    )
                }
            }
        }
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication,
                     didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
    
    // MARK: - Deep Link (URL Scheme)
    
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        print("\n" + String(repeating: "=", count: 60))
        print("📱 [AppDelegate] DeepLink 수신")
        print("   전체 URL: \(url.absoluteString)")
        print("   Scheme: \(url.scheme ?? "nil")")
        print("   Host: \(url.host ?? "nil")")
        print("   Path: \(url.path)")
        
        // URL에서 slink, sLinkT 파라미터 추출
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        
        if let queryItems = components?.queryItems {
            print("📋 쿼리 파라미터:")
            for item in queryItems {
                print("   - \(item.name): \(item.value ?? "nil")")
            }
        }
        
        let slink = components?.queryItems?.first(where: { $0.name == "sLink" || $0.name == "slink" })?.value
        let slinkT = components?.queryItems?.first(where: { $0.name == "sLinkT" })?.value
        
        print("✅ 파싱된 값:")
        print("   sLink: \(slink ?? "nil")")
        print("   sLinkT: \(slinkT ?? "nil")")
        print(String(repeating: "=", count: 60) + "\n")
        
        // Android 가이드 스타일의 updateSlink 메서드 사용
        print("📤 [AppDelegate] SDK.updateSlink() 호출")
        SauceLink.shared.updateSlink(slink, slinkT)
        return true
    }
}

