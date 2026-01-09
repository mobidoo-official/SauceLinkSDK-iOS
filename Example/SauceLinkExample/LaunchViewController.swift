import UIKit

class LaunchViewController: UIViewController {
    
    // MARK: - UI Components
    
    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    private lazy var stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 20
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "SauceLink SDK Test"
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.textAlignment = .center
        return label
    }()
    
    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "테스트 모드를 선택하세요"
        label.font = .systemFont(ofSize: 16)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
    }()
    
    private lazy var urlTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "웹뷰 URL 입력 (예: https://example.com)"
        tf.borderStyle = .roundedRect
        tf.clearButtonMode = .whileEditing
        tf.autocapitalizationType = .none
        tf.keyboardType = .URL
        tf.delegate = self
        tf.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return tf
    }()
    
    private lazy var webViewButton: UIButton = {
        let btn = createButton(
            title: "🌐 웹뷰 실행",
            color: .systemBlue,
            action: #selector(webViewButtonTapped)
        )
        return btn
    }()
    
    private lazy var nativeButton: UIButton = {
        let btn = createButton(
            title: "📱 네이티브 앱 실행",
            color: .systemGreen,
            action: #selector(nativeButtonTapped)
        )
        return btn
    }()
    
    private lazy var infoLabel: UILabel = {
        let label = UILabel()
        label.text = """
        📌 딥링크 테스트:
        • 웹뷰: saucelinktest://saucelink/webview?slink=https://example.com
        • 네이티브: saucelinktest://saucelink/native?slink=code
        • 네이티브+상품: saucelinktest://saucelink/native?slink=code&productId=prod-001
        """
        label.font = .systemFont(ofSize: 11)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        // 키보드 닫기
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(scrollView)
        scrollView.addSubview(stackView)
        
        stackView.addArrangedSubview(createSpacerView(height: 60))
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(subtitleLabel)
        stackView.addArrangedSubview(createSpacerView(height: 40))
        
        // URL 입력 섹션
        let urlSectionLabel = UILabel()
        urlSectionLabel.text = "🌐 웹뷰 테스트"
        urlSectionLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        stackView.addArrangedSubview(urlSectionLabel)
        stackView.addArrangedSubview(urlTextField)
        stackView.addArrangedSubview(webViewButton)
        
        stackView.addArrangedSubview(createDivider())
        
        // 네이티브 섹션
        let nativeSectionLabel = UILabel()
        nativeSectionLabel.text = "📱 네이티브 앱 테스트"
        nativeSectionLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        stackView.addArrangedSubview(nativeSectionLabel)
        stackView.addArrangedSubview(nativeButton)
        
        stackView.addArrangedSubview(createSpacerView(height: 40))
        stackView.addArrangedSubview(infoLabel)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 30),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -30),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -30),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -60)
        ])
    }
    
    private func createButton(title: String, color: UIColor, action: Selector) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        btn.backgroundColor = color
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 12
        btn.heightAnchor.constraint(equalToConstant: 56).isActive = true
        btn.addTarget(self, action: action, for: .touchUpInside)
        return btn
    }
    
    private func createSpacerView(height: CGFloat) -> UIView {
        let view = UIView()
        view.heightAnchor.constraint(equalToConstant: height).isActive = true
        return view
    }
    
    private func createDivider() -> UIView {
        let view = UIView()
        view.backgroundColor = .separator
        view.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return view
    }
    
    // MARK: - Actions
    
    @objc private func webViewButtonTapped() {
        guard let urlString = urlTextField.text?.trimmingCharacters(in: .whitespaces),
              !urlString.isEmpty else {
            showAlert(message: "URL을 입력해주세요")
            return
        }
        
        openWebView(urlString: urlString)
    }
    
    @objc private func nativeButtonTapped() {
        openNativeApp()
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - Navigation
    
    func openWebView(urlString: String) {
        let webVC = WebViewController(urlString: urlString)
        let navController = UINavigationController(rootViewController: webVC)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }
    
    func openNativeApp(productId: String? = nil) {
        let mainVC = MainViewController()
        mainVC.productIdFromDeepLink = productId
        let navController = UINavigationController(rootViewController: mainVC)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }
    
    // MARK: - Helper
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "알림", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITextFieldDelegate

extension LaunchViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        webViewButtonTapped()
        return true
    }
}

