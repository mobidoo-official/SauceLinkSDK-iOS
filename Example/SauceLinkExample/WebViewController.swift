import UIKit
import WebKit

class WebViewController: UIViewController {
    
    // MARK: - Properties
    
    private let urlString: String
    private var webView: WKWebView!
    private var progressView: UIProgressView!
    
    // MARK: - Initialization
    
    init(urlString: String) {
        self.urlString = urlString
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadURL()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "estimatedProgress" {
            progressView.progress = Float(webView.estimatedProgress)
            progressView.isHidden = webView.estimatedProgress >= 1.0
        }
    }
    
    deinit {
        webView.removeObserver(self, forKeyPath: "estimatedProgress")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // 네비게이션 바
        title = "WebView"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(closeTapped)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .refresh,
            target: self,
            action: #selector(refreshTapped)
        )
        
        // 프로그레스 뷰
        progressView = UIProgressView(progressViewStyle: .bar)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(progressView)
        
        // 웹뷰 설정
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        view.addSubview(webView)
        
        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 2),
            
            webView.topAnchor.constraint(equalTo: progressView.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // 프로그레스 관찰
        webView.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
    }
    
    private func loadURL() {
        var urlToLoad = urlString

        // http:// 또는 https://가 없으면 추가
        if !urlToLoad.lowercased().hasPrefix("http://") && !urlToLoad.lowercased().hasPrefix("https://") {
            urlToLoad = "https://" + urlToLoad
        }

        guard let url = URL(string: urlToLoad) else {
            showError(message: "잘못된 URL 형식입니다")
            return
        }

        // URL 파싱 및 slink 추출 로그
        print("\n" + String(repeating: "=", count: 60))
        print("🌐 [WebView] URL 로드 시작")
        print(String(repeating: "-", count: 60))
        print("📋 전체 URL: \(urlToLoad)")
        print("   Scheme: \(url.scheme ?? "nil")")
        print("   Host: \(url.host ?? "nil")")
        print("   Path: \(url.path)")

        // 쿼리 파라미터 추출
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        print(String(repeating: "-", count: 60))
        print("📋 쿼리 파라미터:")
        if let queryItems = components?.queryItems, !queryItems.isEmpty {
            for item in queryItems {
                print("   - \(item.name): \(item.value ?? "nil")")
            }
        } else {
            print("   (없음)")
        }

        // slink, sLinkT 추출
        let slink = components?.queryItems?.first(where: { $0.name == "slink" || $0.name == "sLink" })?.value

        print(String(repeating: "-", count: 60))
        print("🔍 추출된 트래킹 값:")
        print("   slink: \(slink ?? "nil")")
        print(String(repeating: "=", count: 60) + "\n")

        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    // MARK: - Actions
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    @objc private func refreshTapped() {
        webView.reload()
    }
    
    private func showError(message: String) {
        let alert = UIAlertController(title: "오류", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        present(alert, animated: true)
    }
}

// MARK: - WKNavigationDelegate

extension WebViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        progressView.isHidden = false
        print("🌐 웹페이지 로딩 시작")
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        progressView.isHidden = true
        title = webView.title ?? "WebView"
        print("✅ 웹페이지 로딩 완료: \(webView.url?.absoluteString ?? "")")
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        progressView.isHidden = true
        print("❌ 웹페이지 로딩 실패: \(error.localizedDescription)")
        showError(message: "페이지를 불러올 수 없습니다\n\(error.localizedDescription)")
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        // 커스텀 스킴 처리 가능
        if let url = navigationAction.request.url,
           let scheme = url.scheme,
           scheme == "saucelinktest" {
            print("🔗 커스텀 스킴 감지: \(url.absoluteString)")
            // 필요시 딥링크 처리
            decisionHandler(.cancel)
            return
        }
        
        decisionHandler(.allow)
    }
}

