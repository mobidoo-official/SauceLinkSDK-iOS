import UIKit
import SauceLinkSDK

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: windowScene)
        
        // LaunchViewController를 첫 화면으로 설정
        let launchVC = LaunchViewController()
        window?.rootViewController = launchVC
        window?.makeKeyAndVisible()
        
        // 앱 실행 시 딥링크 처리
        if let url = connectionOptions.urlContexts.first?.url {
            print("📱 DeepLink on launch: \(url)")
            handleDeepLink(url: url)
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {}
    func sceneDidBecomeActive(_ scene: UIScene) {}
    func sceneWillResignActive(_ scene: UIScene) {}
    func sceneWillEnterForeground(_ scene: UIScene) {}
    func sceneDidEnterBackground(_ scene: UIScene) {}
    
    // MARK: - Deep Link (URL Scheme)
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        print("📱 DeepLink received: \(url)")
        handleDeepLink(url: url)
    }
    
    // MARK: - Universal Link
    
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        guard let url = userActivity.webpageURL else { return }
        print("🔗 Universal Link received: \(url)")
        handleDeepLink(url: url)
    }
    
    // MARK: - Deep Link Handler
    
    private func handleDeepLink(url: URL) {
        print("\n" + String(repeating: "=", count: 60))
        print("🔗 딥링크 수신 및 파싱 시작")
        print("   전체 URL: \(url.absoluteString)")
        print("   Scheme: \(url.scheme ?? "nil")")
        print("   Host: \(url.host ?? "nil")")
        print("   Path: \(url.path)")
        print(String(repeating: "-", count: 60))
        
        // 쿼리 파라미터 추출
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        
        print("📋 쿼리 파라미터 파싱:")
        if let queryItems = components?.queryItems {
            for item in queryItems {
                print("   - \(item.name): \(item.value ?? "nil")")
            }
        } else {
            print("   - 쿼리 파라미터 없음")
        }
        
        // 웹뷰용 URL 파라미터 (url= 이후 전체를 가져옴, 인코딩 문제 해결)
        var webUrl: String? = nil
        if let query = url.query, query.contains("url=") {
            if let range = query.range(of: "url=") {
                webUrl = String(query[range.upperBound...])
                // URL 디코딩 (인코딩된 경우 대비)
                webUrl = webUrl?.removingPercentEncoding ?? webUrl

                // 쿼리 파라미터가 ?로 시작하지 않으면 첫 번째 &를 ?로 변환
                if let extractedUrl = webUrl, !extractedUrl.contains("?") {
                    if let firstAmpersand = extractedUrl.firstIndex(of: "&") {
                        var fixedUrl = extractedUrl
                        fixedUrl.replaceSubrange(firstAmpersand...firstAmpersand, with: "?")
                        webUrl = fixedUrl
                    }
                }
            }
        }
        // 네이티브용 sLink 파라미터
        let slinkValue = components?.queryItems?.first(where: { $0.name == "sLink" || $0.name == "slink" })?.value
        let productId = components?.queryItems?.first(where: { $0.name == "productId" })?.value

        print(String(repeating: "-", count: 60))
        print("✅ 파싱된 값:")
        print("   url (웹뷰용): \(webUrl ?? "nil")")
        print("   sLink (네이티브용): \(slinkValue ?? "nil")")
        print("   productId: \(productId ?? "nil")")
        print(String(repeating: "=", count: 60) + "\n")
        
        // URL 파싱
        // 웹뷰: saucelinktest://saucelink/webview?url=https://example.com?slink=abc123
        // 네이티브: saucelinktest://saucelink/native?slink=abc123&sLinkT=999&productId=prod-001
        
        guard url.scheme == "saucelinktest",
              url.host == "saucelink" else {
            print("⚠️ 올바르지 않은 스킴 형식")
            print("   기대: saucelinktest://saucelink/...")
            print("   실제: \(url.scheme ?? "nil")://\(url.host ?? "nil")/...")
            return
        }
        
        let path = url.path.replacingOccurrences(of: "/", with: "")
        
        guard let rootVC = window?.rootViewController as? LaunchViewController else {
            print("⚠️ LaunchViewController를 찾을 수 없습니다")
            return
        }
        
        switch path {
        case "webview":
            // 웹뷰 열기: url 파라미터 사용
            if let urlString = webUrl, !urlString.isEmpty {
                print("🌐 웹뷰 모드: \(urlString)")
                print("   (sLink 추출은 웹뷰 내부에서 처리)")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    rootVC.openWebView(urlString: urlString)
                }
            } else {
                print("⚠️ 웹뷰 URL이 없습니다 (url 파라미터 필요)")
            }

        case "native":
            // 네이티브 앱 열기: sLink로 updateSlink 호출
            print("📤 SDK.updateSlink() 호출: sLink=\(slinkValue ?? "nil")")
            SauceLink.shared.updateSlink(slinkValue)

            if let productId = productId {
                print("📱 네이티브 모드: sLink=\(slinkValue ?? ""), productId=\(productId)")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    rootVC.openNativeApp(productId: productId)
                }
            } else {
                print("📱 네이티브 모드: sLink=\(slinkValue ?? "")")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    rootVC.openNativeApp()
                }
            }

        default:
            print("⚠️ 알 수 없는 경로: \(path)")
        }
    }
}

