import UIKit
import SauceLinkSDK

protocol SettingsViewControllerDelegate: AnyObject {
    func settingsDidSave()
}

class SettingsViewController: UIViewController {
    
    weak var delegate: SettingsViewControllerDelegate?
    
    // MARK: - UI Components
    
    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.keyboardDismissMode = .interactive
        return sv
    }()
    
    private lazy var stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 20
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    private lazy var partnerIdTextField: UITextField = {
        let tf = createTextField(placeholder: "Partner Unique ID")
        tf.text = ConfigManager.shared.partnerUniqueId
        return tf
    }()
    
    private lazy var tokenTextField: UITextField = {
        let tf = createTextField(placeholder: "SDK Token (sla_xxx)")
        tf.text = ConfigManager.shared.token
        return tf
    }()
    
    private lazy var productIdTextField: UITextField = {
        let tf = createTextField(placeholder: "기본 상품 ID")
        tf.text = ConfigManager.shared.defaultProductId
        return tf
    }()
    
    private lazy var orderIdTextField: UITextField = {
        let tf = createTextField(placeholder: "기본 주문 ID")
        tf.text = ConfigManager.shared.defaultOrderId
        return tf
    }()
    
    private lazy var productNameTextField: UITextField = {
        let tf = createTextField(placeholder: "상품명")
        tf.text = ConfigManager.shared.productName
        return tf
    }()
    
    private lazy var productPriceTextField: UITextField = {
        let tf = createTextField(placeholder: "상품 가격")
        tf.keyboardType = .numberPad
        tf.text = ConfigManager.shared.productPrice
        return tf
    }()
    
    private lazy var productDiscountPriceTextField: UITextField = {
        let tf = createTextField(placeholder: "상품 할인 가격")
        tf.keyboardType = .numberPad
        tf.text = ConfigManager.shared.productDiscountPrice
        return tf
    }()
    
    private lazy var slinkTextField: UITextField = {
        let tf = createTextField(placeholder: "sLink 코드 (선택)")
        tf.text = ConfigManager.shared.slink
        return tf
    }()
    
    private lazy var environmentSegmentedControl: UISegmentedControl = {
        let items = ["Stage", "Prod"]
        let sc = UISegmentedControl(items: items)
        
        // 현재 환경에 맞게 선택
        switch ConfigManager.shared.environment {
        case .stage:
            sc.selectedSegmentIndex = 0
        case .prod:
            sc.selectedSegmentIndex = 1
        }
        
        sc.heightAnchor.constraint(equalToConstant: 44).isActive = true
        return sc
    }()
    
    private lazy var saveButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("저장", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        btn.backgroundColor = .systemBlue
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 12
        btn.heightAnchor.constraint(equalToConstant: 54).isActive = true
        btn.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        return btn
    }()
    
    private lazy var clearButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("모두 지우기", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .regular)
        btn.setTitleColor(.systemRed, for: .normal)
        btn.addTarget(self, action: #selector(clearTapped), for: .touchUpInside)
        return btn
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupKeyboardObservers()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        title = "설정"
        view.backgroundColor = .systemBackground
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeTapped)
        )
        
        // 화면 탭하면 키보드 닫기
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        
        view.addSubview(scrollView)
        scrollView.addSubview(stackView)
        
        // 섹션 추가
        addSection(title: "SDK 설정", fields: [
            ("Partner ID", partnerIdTextField),
            ("Token", tokenTextField)
        ])
        
        addEnvironmentSection()
        
        addSection(title: "테스트 기본값", fields: [
            ("상품 ID", productIdTextField),
            ("주문 ID", orderIdTextField)
        ])
        
        addSection(title: "상품 정보 (딥링크용)", fields: [
            ("상품명", productNameTextField),
            ("상품 가격", productPriceTextField),
            ("할인 가격", productDiscountPriceTextField)
        ])
        
        addSection(title: "소스링크 설정 (선택)", fields: [
            ("sLink", slinkTextField)
        ])
        
        stackView.addArrangedSubview(saveButton)
        stackView.addArrangedSubview(clearButton)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        ])
    }
    
    private func addSection(title: String, fields: [(String, UITextField)]) {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        stackView.addArrangedSubview(titleLabel)
        
        for (label, textField) in fields {
            let fieldLabel = UILabel()
            fieldLabel.text = label
            fieldLabel.font = .systemFont(ofSize: 14, weight: .medium)
            fieldLabel.textColor = .secondaryLabel
            
            stackView.addArrangedSubview(fieldLabel)
            stackView.addArrangedSubview(textField)
        }
    }
    
    private func addEnvironmentSection() {
        let titleLabel = UILabel()
        titleLabel.text = "환경 설정"
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        stackView.addArrangedSubview(titleLabel)
        
        let fieldLabel = UILabel()
        fieldLabel.text = "API 환경"
        fieldLabel.font = .systemFont(ofSize: 14, weight: .medium)
        fieldLabel.textColor = .secondaryLabel
        
        stackView.addArrangedSubview(fieldLabel)
        stackView.addArrangedSubview(environmentSegmentedControl)
    }
    
    private func createTextField(placeholder: String) -> UITextField {
        let tf = UITextField()
        tf.placeholder = placeholder
        tf.borderStyle = .roundedRect
        tf.font = .systemFont(ofSize: 16)
        tf.autocapitalizationType = .none
        tf.autocorrectionType = .no
        tf.returnKeyType = .next
        tf.delegate = self
        tf.heightAnchor.constraint(equalToConstant: 44).isActive = true
        return tf
    }
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    // MARK: - Actions
    
    @objc private func saveTapped() {
        guard let partnerId = partnerIdTextField.text, !partnerId.isEmpty,
              let token = tokenTextField.text, !token.isEmpty else {
            showAlert(title: "입력 오류", message: "Partner ID와 Token은 필수입니다.")
            return
        }
        
        // 환경 설정 저장
        let selectedEnvironment: Environment
        switch environmentSegmentedControl.selectedSegmentIndex {
        case 0:
            selectedEnvironment = .stage
        case 1:
            selectedEnvironment = .prod
        default:
            selectedEnvironment = .stage
        }
        ConfigManager.shared.environment = selectedEnvironment
        
        print("\n" + String(repeating: "=", count: 60))
        print("💾 설정 저장 중...")
        print("   Partner ID: \(partnerId)")
        print("   Token: \(token)")
        print("   Environment: \(selectedEnvironment.rawValue)")
        print("   Product ID: \(productIdTextField.text ?? "")")
        print("   Order ID: \(orderIdTextField.text ?? "")")
        print(String(repeating: "=", count: 60))
        
        ConfigManager.shared.saveConfig(
            partnerUniqueId: partnerId,
            token: token,
            defaultProductId: productIdTextField.text ?? "",
            defaultOrderId: orderIdTextField.text ?? "",
            productName: productNameTextField.text ?? "",
            productPrice: productPriceTextField.text ?? "",
            productDiscountPrice: productDiscountPriceTextField.text ?? "",
            slink: slinkTextField.text ?? ""
        )
        
        print("✅ UserDefaults에 저장 완료")
        print("   확인: isConfigured = \(ConfigManager.shared.isConfigured)")
        print("   확인: 저장된 Partner ID = '\(ConfigManager.shared.partnerUniqueId)'")
        print("   확인: 저장된 Token = '\(ConfigManager.shared.token)'")
        
        // SDK 재초기화 (설정 변경 즉시 적용)
        print("\n⚙️ SDK 재초기화 시작")
        
        // 기존 SDK 상태 초기화
        AppDelegate.sdkInitialized = false
        AppDelegate.sdkAuthSuccess = false
        AppDelegate.sdkAuthStatusCode = 0
        
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.initializeSDK()
        }
        
        showAlert(title: "저장 완료", message: "설정이 저장되고 SDK가 재초기화되었습니다.\n콘솔 로그를 확인해주세요.") { [weak self] in
            self?.delegate?.settingsDidSave()
            self?.dismiss(animated: true)
        }
    }
    
    @objc private func clearTapped() {
        let alert = UIAlertController(
            title: "모두 지우기",
            message: "저장된 모든 설정을 삭제하시겠습니까?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "삭제", style: .destructive) { [weak self] _ in
            ConfigManager.shared.clearAll()
            self?.partnerIdTextField.text = ""
            self?.tokenTextField.text = ""
            self?.productIdTextField.text = ""
            self?.orderIdTextField.text = ""
            self?.productNameTextField.text = ""
            self?.productPriceTextField.text = ""
            self?.productDiscountPriceTextField.text = ""
            self?.slinkTextField.text = ""
            self?.environmentSegmentedControl.selectedSegmentIndex = 0 // Stage로 초기화
            self?.showAlert(title: "삭제 완료", message: "모든 설정이 삭제되었습니다.")
        })
        
        present(alert, animated: true)
    }
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }
        
        let contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardFrame.height, right: 0)
        scrollView.contentInset = contentInset
        scrollView.scrollIndicatorInsets = contentInset
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
    }
    
    // MARK: - Helpers
    
    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }
}

// MARK: - UITextFieldDelegate

extension SettingsViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == partnerIdTextField {
            tokenTextField.becomeFirstResponder()
        } else if textField == tokenTextField {
            productIdTextField.becomeFirstResponder()
        } else if textField == productIdTextField {
            orderIdTextField.becomeFirstResponder()
        } else if textField == orderIdTextField {
            productNameTextField.becomeFirstResponder()
        } else if textField == productNameTextField {
            productPriceTextField.becomeFirstResponder()
        } else if textField == productPriceTextField {
            productDiscountPriceTextField.becomeFirstResponder()
        } else if textField == productDiscountPriceTextField {
            slinkTextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }
}
