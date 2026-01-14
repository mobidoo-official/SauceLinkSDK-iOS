import UIKit
import SauceLinkSDK

// MARK: - Product Model
struct CartProduct {
    let productId: String
    let productName: String
    let price: Int
    let discountPrice: Int
    var quantity: Int
}

class MainViewController: UIViewController, SettingsViewControllerDelegate {
    
    // MARK: - Properties
    
    private var cart: [CartProduct] = []
    var productIdFromDeepLink: String? = nil
    
    // SDK 초기화 상태 저장 (notification에서 받은 값)
    private var lastSDKAuthSuccess: Bool? = nil
    private var lastSDKAuthStatusCode: Int = 0
    
    // MARK: - UI Components
    
    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    private lazy var stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 16
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "SauceLink Tracker"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var configLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var sdkStatusView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var sdkStatusStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 8
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.layoutMargins = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        sv.isLayoutMarginsRelativeArrangement = true
        return sv
    }()
    
    private lazy var sdkStatusTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "📊 SDK 상태"
        label.font = .systemFont(ofSize: 16, weight: .bold)
        return label
    }()
    
    private lazy var tokenStatusLabel: UILabel = {
        let label = UILabel()
        label.text = "토큰 인증: 대기중..."
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private lazy var lastEventStatusLabel: UILabel = {
        let label = UILabel()
        label.text = "마지막 전송: -"
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private lazy var environmentLabel: UILabel = {
        let label = UILabel()
        label.text = "환경: -"
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        return label
    }()
    
    // MARK: - 카트 관련 UI
    
    private lazy var addProductAButton: UIButton = {
        let btn = createButton(title: "🛒 상품A 추가 (10,000원→8,500원)", color: .systemBlue)
        btn.addTarget(self, action: #selector(addProductATapped), for: .touchUpInside)
        return btn
    }()
    
    private lazy var addProductBButton: UIButton = {
        let btn = createButton(title: "🛒 상품B 추가 (5,000원→4,500원)", color: .systemBlue)
        btn.addTarget(self, action: #selector(addProductBTapped), for: .touchUpInside)
        return btn
    }()
    
    private lazy var cartTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "🛒 현재 카트 (0개)"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        return label
    }()
    
    private lazy var cartTableView: UITableView = {
        let tv = UITableView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "CartCell")
        tv.delegate = self
        tv.dataSource = self
        tv.layer.cornerRadius = 8
        tv.layer.borderWidth = 1
        tv.layer.borderColor = UIColor.separator.cgColor
        tv.isScrollEnabled = false
        return tv
    }()
    
    private lazy var clearCartButton: UIButton = {
        let btn = createButton(title: "🗑️ 카트 비우기", color: .systemGray)
        btn.addTarget(self, action: #selector(clearCartTapped), for: .touchUpInside)
        return btn
    }()
    
    // MARK: - 이벤트 전송 UI
    
    private lazy var productDetailButton: UIButton = {
        let btn = createButton(title: "📊 상품 상세 이벤트", color: .systemGreen)
        btn.addTarget(self, action: #selector(trackProductDetailTapped), for: .touchUpInside)
        return btn
    }()
    
    private lazy var orderCompleteButton: UIButton = {
        let btn = createButton(title: "📊 주문 완료 이벤트", color: .systemOrange)
        btn.addTarget(self, action: #selector(trackOrderCompleteTapped), for: .touchUpInside)
        return btn
    }()
    
    private lazy var orderCancelButton: UIButton = {
        let btn = createButton(title: "📊 주문 취소 이벤트", color: .systemRed)
        btn.addTarget(self, action: #selector(trackOrderCancelTapped), for: .touchUpInside)
        return btn
    }()
    
    private lazy var testDeepLinkButton: UIButton = {
        let btn = createButton(title: "🔗 딥링크 테스트", color: .systemPurple)
        btn.addTarget(self, action: #selector(testDeepLinkTapped), for: .touchUpInside)
        return btn
    }()
    
    private lazy var logTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "📝 실시간 로그"
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        return label
    }()
    
    private lazy var clearLogButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("🧹 로그 지우기", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 14)
        btn.addTarget(self, action: #selector(clearLogTapped), for: .touchUpInside)
        return btn
    }()
    
    private lazy var logTextView: UITextView = {
        let tv = UITextView()
        tv.isEditable = false
        tv.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        tv.backgroundColor = .secondarySystemBackground
        tv.layer.cornerRadius = 8
        tv.layer.borderWidth = 1
        tv.layer.borderColor = UIColor.separator.cgColor
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.text = "로그가 여기에 표시됩니다...\n"
        return tv
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateConfigDisplay()
        updateEnvironmentLabel()
        
        // SDK 초기화 알림 수신
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sdkInitialized(_:)),
            name: NSNotification.Name("SDKInitialized"),
            object: nil
        )
        
        // 초기 상태는 "초기화 중"으로 표시
        tokenStatusLabel.text = "토큰 인증: 초기화 중..."
        tokenStatusLabel.textColor = .systemOrange
        appendLog("앱 시작 - SDK 초기화 중")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func sdkInitialized(_ notification: Notification) {
        print("📢 [MainViewController] SDKInitialized notification 수신")
        
        guard let userInfo = notification.userInfo,
              let success = userInfo["success"] as? Bool,
              let statusCode = userInfo["statusCode"] as? Int else {
            print("⚠️ [MainViewController] notification userInfo 파싱 실패")
            return
        }
        
        print("📢 [MainViewController] SDK 상태: success=\(success), statusCode=\(statusCode)")
        
        // SDK 상태 저장
        self.lastSDKAuthSuccess = success
        self.lastSDKAuthStatusCode = statusCode
        
        // 메인 스레드에서 UI 업데이트 보장
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.updateTokenStatus(success: success, statusCode: statusCode)
            
            if success {
                self.appendLog("✅ SDK 초기화 성공 (토큰 인증: HTTP \(statusCode))")
            } else {
                self.appendLog("❌ SDK 초기화 실패 (토큰 인증: HTTP \(statusCode))")
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateConfigDisplay()
        updateEnvironmentLabel()
        
        // 1초 후 SDK 상태 확인 (notification을 못받은 경우 대비)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.checkSDKStatusIfNeeded()
        }
        
        // 딥링크에서 productId가 전달되었으면 자동으로 PRODUCT_DETAIL 이벤트 호출
        if let productId = productIdFromDeepLink {
            productIdFromDeepLink = nil // 한 번만 실행되도록
            handleDeepLinkProductDetail(productId: productId)
        }
    }
    
    /// SDK 상태 확인 (notification을 못받은 경우에만)
    private func checkSDKStatusIfNeeded() {
        // notification을 이미 받았으면 아무것도 안함
        if let success = lastSDKAuthSuccess {
            print("✅ [MainViewController] Notification 이미 수신됨 (success=\(success), code=\(lastSDKAuthStatusCode))")
            return
        }
        
        // 아직 notification을 못받았으면 SDK에서 직접 확인
        print("⚠️ [MainViewController] Notification 미수신 - SDK 상태 직접 확인")
        updateSDKStatusFromSDK()
    }
    
    /// SDK에서 직접 상태를 가져와서 UI 업데이트
    private func updateSDKStatusFromSDK() {
        print("🔍 [MainViewController] SDK 상태 확인:")
        print("   AppDelegate.sdkInitialized: \(AppDelegate.sdkInitialized)")
        print("   AppDelegate.sdkAuthSuccess: \(AppDelegate.sdkAuthSuccess)")
        print("   AppDelegate.sdkAuthStatusCode: \(AppDelegate.sdkAuthStatusCode)")
        
        if AppDelegate.sdkInitialized {
            // SDK 초기화가 완료된 경우
            let success = AppDelegate.sdkAuthSuccess
            let statusCode = AppDelegate.sdkAuthStatusCode
            
            self.lastSDKAuthSuccess = success
            self.lastSDKAuthStatusCode = statusCode
            
            self.updateTokenStatus(success: success, statusCode: statusCode)
            
            if success {
                self.appendLog("✅ SDK 초기화 완료 (토큰 인증: \(statusCode))")
            } else {
                self.appendLog("❌ SDK 초기화 실패 (토큰 인증: \(statusCode))")
            }
        } else {
            // 아직 초기화 중
            self.tokenStatusLabel.text = "토큰 인증: 초기화 중..."
            self.tokenStatusLabel.textColor = .systemOrange
            
            // 1초 더 기다렸다가 다시 확인
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.updateSDKStatusFromSDK()
            }
        }
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        title = "SDK Test"
        view.backgroundColor = .systemBackground
        
        // 뒤로가기 버튼
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )
        
        // 설정 버튼
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "gearshape.fill"),
            style: .plain,
            target: self,
            action: #selector(settingsTapped)
        )
        
        // 화면 탭하면 키보드 닫기
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        
        view.addSubview(scrollView)
        scrollView.addSubview(stackView)
        
        // 헤더
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(configLabel)
        
        // SDK 상태 뷰
        sdkStatusView.addSubview(sdkStatusStack)
        sdkStatusStack.addArrangedSubview(sdkStatusTitleLabel)
        sdkStatusStack.addArrangedSubview(tokenStatusLabel)
        sdkStatusStack.addArrangedSubview(lastEventStatusLabel)
        sdkStatusStack.addArrangedSubview(environmentLabel)
        stackView.addArrangedSubview(sdkStatusView)
        
        NSLayoutConstraint.activate([
            sdkStatusStack.topAnchor.constraint(equalTo: sdkStatusView.topAnchor),
            sdkStatusStack.leadingAnchor.constraint(equalTo: sdkStatusView.leadingAnchor),
            sdkStatusStack.trailingAnchor.constraint(equalTo: sdkStatusView.trailingAnchor),
            sdkStatusStack.bottomAnchor.constraint(equalTo: sdkStatusView.bottomAnchor)
        ])
        
        stackView.addArrangedSubview(createSeparator())
        
        // 상품 추가 섹션
        let addProductLabel = UILabel()
        addProductLabel.text = "🛒 상품 카트 추가"
        addProductLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        stackView.addArrangedSubview(addProductLabel)
        stackView.addArrangedSubview(addProductAButton)
        stackView.addArrangedSubview(addProductBButton)
        stackView.addArrangedSubview(createSeparator())
        
        // 카트 섹션
        stackView.addArrangedSubview(cartTitleLabel)
        stackView.addArrangedSubview(cartTableView)
        stackView.addArrangedSubview(clearCartButton)
        stackView.addArrangedSubview(createSeparator())
        
        // 이벤트 전송 섹션
        let eventLabel = UILabel()
        eventLabel.text = "📊 이벤트 전송"
        eventLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        stackView.addArrangedSubview(eventLabel)
        
        let infoLabel = UILabel()
        infoLabel.text = "ℹ️ 카트에 추가된 상품으로 이벤트를 전송합니다"
        infoLabel.font = .systemFont(ofSize: 12)
        infoLabel.textColor = .secondaryLabel
        infoLabel.numberOfLines = 0
        stackView.addArrangedSubview(infoLabel)
        
        stackView.addArrangedSubview(productDetailButton)
        stackView.addArrangedSubview(orderCompleteButton)
        stackView.addArrangedSubview(orderCancelButton)
        stackView.addArrangedSubview(testDeepLinkButton)
        stackView.addArrangedSubview(createSeparator())
        
        // 로그 섹션
        let logHeaderStack = UIStackView()
        logHeaderStack.axis = .horizontal
        logHeaderStack.distribution = .equalSpacing
        logHeaderStack.addArrangedSubview(logTitleLabel)
        logHeaderStack.addArrangedSubview(clearLogButton)
        stackView.addArrangedSubview(logHeaderStack)
        stackView.addArrangedSubview(logTextView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40),
            
            cartTableView.heightAnchor.constraint(equalToConstant: 150),
            logTextView.heightAnchor.constraint(equalToConstant: 200)
        ])
    }
    
    private func createSeparator() -> UIView {
        let view = UIView()
        view.backgroundColor = .separator
        view.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return view
    }
    
    private func createButton(title: String, color: UIColor) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        btn.backgroundColor = color
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 10
        btn.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return btn
    }
    
    private func updateTokenStatus(success: Bool, statusCode: Int? = nil) {
        if success {
            tokenStatusLabel.text = "✅ 토큰 인증: 성공 (\(statusCode ?? 200))"
            tokenStatusLabel.textColor = .systemGreen
        } else {
            let code = statusCode != nil ? " (\(statusCode!))" : ""
            tokenStatusLabel.text = "❌ 토큰 인증: 실패\(code)"
            tokenStatusLabel.textColor = .systemRed
        }
    }
    
    private func updateLastEventStatus(eventName: String, success: Bool, statusCode: Int? = nil) {
        if success {
            lastEventStatusLabel.text = "✅ 마지막 전송: \(eventName) 성공 (\(statusCode ?? 200))"
            lastEventStatusLabel.textColor = .systemGreen
        } else {
            let code = statusCode != nil ? " (\(statusCode!))" : ""
            lastEventStatusLabel.text = "❌ 마지막 전송: \(eventName) 실패\(code)"
            lastEventStatusLabel.textColor = .systemRed
        }
    }
    
    private func updateEnvironmentLabel() {
        let config = ConfigManager.shared
        environmentLabel.text = "환경: \(config.environmentDisplayName) | Partner: \(config.partnerUniqueId.prefix(10))..."
    }
    
    private func updateConfigDisplay() {
        let config = ConfigManager.shared
        
        if config.isConfigured {
            let productIdText = config.defaultProductId.isEmpty ? "미설정" : config.defaultProductId
            let orderIdText = config.defaultOrderId.isEmpty ? "미설정" : config.defaultOrderId
            
            configLabel.text = """
            Partner: \(config.partnerUniqueId)
            Token: \(config.token.prefix(20))...
            상품 ID: \(productIdText)
            주문 ID: \(orderIdText)
            """
        } else {
            configLabel.text = "⚠️ 설정이 필요합니다. 오른쪽 상단 톱니바퀴를 눌러주세요."
        }
    }
    
    private func appendLog(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        logTextView.text += "[\(timestamp)] \(message)\n"
        
        // 스크롤 맨 아래로
        let bottom = NSRange(location: logTextView.text.count - 1, length: 1)
        logTextView.scrollRangeToVisible(bottom)
    }
    
    private func updateCartUI() {
        cartTitleLabel.text = "🛒 현재 카트 (\(cart.count)개)"
        cartTableView.reloadData()
        
        // 테이블뷰 높이 동적 조정
        let height = max(50, min(CGFloat(cart.count * 60), 200))
        cartTableView.constraints.first { $0.firstAttribute == .height }?.constant = height
    }
    
    // MARK: - Actions
    
    @objc private func settingsTapped() {
        let settingsVC = SettingsViewController()
        settingsVC.delegate = self
        let navController = UINavigationController(rootViewController: settingsVC)
        present(navController, animated: true)
    }
    
    @objc private func addProductATapped() {
        let product = CartProduct(
            productId: ConfigManager.shared.defaultProductId.isEmpty ? "prod-A" : ConfigManager.shared.defaultProductId,
            productName: "테스트 상품 A",
            price: 10000,
            discountPrice: 8500,
            quantity: 1
        )
        cart.append(product)
        updateCartUI()
        appendLog("✅ 상품A 카트에 추가됨")
    }
    
    @objc private func addProductBTapped() {
        let product = CartProduct(
            productId: "prod-B",
            productName: "테스트 상품 B",
            price: 5000,
            discountPrice: 4500,
            quantity: 1
        )
        cart.append(product)
        updateCartUI()
        appendLog("✅ 상품B 카트에 추가됨")
    }
    
    @objc private func clearCartTapped() {
        cart.removeAll()
        updateCartUI()
        appendLog("🗑️ 카트가 비워졌습니다")
    }
    
    @objc private func clearLogTapped() {
        logTextView.text = ""
        appendLog("로그가 초기화되었습니다")
    }
    
    @objc private func trackProductDetailTapped() {
        if cart.isEmpty {
            appendLog("⚠️ 카트가 비어있습니다. 먼저 상품을 추가해주세요.")
            return
        }

        // ProductDetailInfo 객체 배열로 변환 (quantity, currency 없음)
        let products = cart.map { product in
            ProductDetailInfo(
                product_id: product.productId,
                product_name: product.productName,
                price: "\(product.price)",
                discount_price: "\(product.discountPrice)"
            )
        }

        appendLog("📤 PRODUCT_DETAIL 이벤트 전송 중... (\(cart.count)개 상품)")
        print("📤 [SauceLinkSDK] PRODUCT_DETAIL 이벤트 전송 (\(cart.count)개 상품)")
        for (index, product) in products.enumerated() {
            appendLog("   상품\(index + 1): product_id=\(product.product_id), name=\(product.product_name), price=\(product.price)")
            print("   상품\(index + 1): product_id=\(product.product_id), name=\(product.product_name), price=\(product.price), discount_price=\(product.discount_price)")
        }

        // 첫 번째 상품만 trackProductDetail로 전송
        if let firstProduct = products.first {
            SauceLink.shared.trackProductDetail(product: firstProduct) { [weak self] result in
                guard let self = self else { return }

                switch result {
                case .success:
                    self.updateLastEventStatus(eventName: "PRODUCT_DETAIL", success: true, statusCode: 200)
                    self.appendLog("✅ PRODUCT_DETAIL 전송 성공 (HTTP 200)")
                case .failure(let error):
                    let statusCode = (error as NSError).code
                    self.updateLastEventStatus(eventName: "PRODUCT_DETAIL", success: false, statusCode: statusCode)
                    self.appendLog("❌ PRODUCT_DETAIL 전송 실패 (HTTP \(statusCode))")
                }
            }
        }
    }
    
    @objc private func trackOrderCompleteTapped() {
        if cart.isEmpty {
            appendLog("⚠️ 카트가 비어있습니다. 먼저 상품을 추가해주세요.")
            return
        }

        let orderId = ConfigManager.shared.defaultOrderId.isEmpty ? "order-\(Int.random(in: 1000...9999))" : ConfigManager.shared.defaultOrderId

        // OrderProductInfo 객체 배열로 변환 (quantity 포함, currency 없음)
        let products = cart.map { product in
            OrderProductInfo(
                product_id: product.productId,
                product_name: product.productName,
                price: "\(product.price)",
                discount_price: "\(product.discountPrice)",
                quantity: product.quantity
            )
        }

        appendLog("📤 ORDER_COMPLETE 이벤트 전송 중... (주문: \(orderId))")
        print("📤 [SauceLinkSDK] ORDER_COMPLETE 이벤트 전송 (주문: \(orderId))")
        for (index, product) in products.enumerated() {
            appendLog("   상품\(index + 1): product_id=\(product.product_id), name=\(product.product_name), price=\(product.price)")
            print("   상품\(index + 1): product_id=\(product.product_id), name=\(product.product_name), price=\(product.price), discount_price=\(product.discount_price), quantity=\(product.quantity)")
        }

        SauceLink.shared.trackOrderComplete(orderId: orderId, products: products) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success:
                self.updateLastEventStatus(eventName: "ORDER_COMPLETE", success: true, statusCode: 200)
                self.appendLog("✅ ORDER_COMPLETE 전송 성공 (주문: \(orderId), HTTP 200)")
            case .failure(let error):
                let statusCode = (error as NSError).code
                self.updateLastEventStatus(eventName: "ORDER_COMPLETE", success: false, statusCode: statusCode)
                self.appendLog("❌ ORDER_COMPLETE 전송 실패 (주문: \(orderId), HTTP \(statusCode))")
            }
        }
    }

    
    @objc private func trackOrderCancelTapped() {
        if cart.isEmpty {
            appendLog("⚠️ 카트가 비어있습니다. 먼저 상품을 추가해주세요.")
            return
        }

        let orderId = ConfigManager.shared.defaultOrderId.isEmpty ? "order-1234" : ConfigManager.shared.defaultOrderId

        // OrderProductInfo 객체 배열로 변환 (quantity 포함, currency 없음)
        let products = cart.map { product in
            OrderProductInfo(
                product_id: product.productId,
                product_name: product.productName,
                price: "\(product.price)",
                discount_price: "\(product.discountPrice)",
                quantity: product.quantity
            )
        }

        appendLog("📤 ORDER_CANCEL 이벤트 전송 중... (주문: \(orderId))")
        print("📤 [SauceLinkSDK] ORDER_CANCEL 이벤트 전송 (주문: \(orderId))")
        for (index, product) in products.enumerated() {
            appendLog("   상품\(index + 1): product_id=\(product.product_id), name=\(product.product_name), price=\(product.price)")
            print("   상품\(index + 1): product_id=\(product.product_id), name=\(product.product_name), price=\(product.price), discount_price=\(product.discount_price), quantity=\(product.quantity)")
        }

        SauceLink.shared.trackOrderCancel(orderId: orderId, products: products) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success:
                self.updateLastEventStatus(eventName: "ORDER_CANCEL", success: true, statusCode: 200)
                self.appendLog("✅ ORDER_CANCEL 전송 성공 (주문: \(orderId), HTTP 200)")
            case .failure(let error):
                let statusCode = (error as NSError).code
                self.updateLastEventStatus(eventName: "ORDER_CANCEL", success: false, statusCode: statusCode)
                self.appendLog("❌ ORDER_CANCEL 전송 실패 (주문: \(orderId), HTTP \(statusCode))")
            }
        }
    }
    
    @objc private func testDeepLinkTapped() {
        // 테스트용 딥링크 시뮬레이션 (네이티브 모드)
        let slink = "test123abc"
        let slinkT = "\(Int(Date().timeIntervalSince1970) + 86400)"
        
        // Android 가이드 스타일: updateSlink 사용
        SauceLink.shared.updateSlink(slink, slinkT)
        appendLog("DeepLink simulated: slink=\(slink), sLinkT=\(slinkT)")
    }
    
    // MARK: - Deep Link Product Detail
    
    private func handleDeepLinkProductDetail(productId: String) {
        appendLog("🔗 딥링크로부터 productId 수신: \(productId)")
        
        // 설정창에서 저장된 상품 정보 사용, 없으면 기본값
        let config = ConfigManager.shared
        let defaultProductId = config.defaultProductId.isEmpty ? productId : config.defaultProductId
        let productName = config.productName.isEmpty ? "딥링크 상품" : config.productName
        let productPrice = config.productPrice.isEmpty ? "10000" : config.productPrice
        let productDiscountPrice = config.productDiscountPrice.isEmpty ? "8500" : config.productDiscountPrice
        
        // 카트에 상품 추가
        let cartProduct = CartProduct(
            productId: productId,  // 딥링크에서 받은 productId 우선 사용
            productName: productName,
            price: Int(productPrice) ?? 10000,
            discountPrice: Int(productDiscountPrice) ?? 8500,
            quantity: 1
        )
        
        cart.append(cartProduct)
        cartTableView.reloadData()
        appendLog("🛒 카트에 상품 추가: \(productId)")
        
        // ProductDetailInfo 생성 (quantity, currency 없음)
        let product = ProductDetailInfo(
            product_id: productId,
            product_name: productName,
            price: productPrice,
            discount_price: productDiscountPrice
        )
        
        appendLog("📤 PRODUCT_DETAIL 이벤트 자동 전송 중... (productId: \(productId))")
        
        // PRODUCT_DETAIL 이벤트 전송
        SauceLink.shared.trackProductDetail(product: product) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success:
                self.updateLastEventStatus(eventName: "PRODUCT_DETAIL", success: true, statusCode: 200)
                self.appendLog("✅ PRODUCT_DETAIL 전송 성공 (딥링크, HTTP 200)")
            case .failure(let error):
                let statusCode = (error as NSError).code
                self.updateLastEventStatus(eventName: "PRODUCT_DETAIL", success: false, statusCode: statusCode)
                self.appendLog("❌ PRODUCT_DETAIL 전송 실패 (딥링크, HTTP \(statusCode))")
            }
        }
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func backTapped() {
        dismiss(animated: true)
    }
    
    // MARK: - SettingsViewControllerDelegate
    
    func settingsDidSave() {
        print("📢 [MainViewController] settingsDidSave 호출됨")
        updateConfigDisplay()
        updateEnvironmentLabel()
        
        // 저장된 SDK 상태 초기화 (새로운 notification 대기)
        lastSDKAuthSuccess = nil
        lastSDKAuthStatusCode = 0
        
        // 설정 변경 후 SDK 재초기화 대기 상태로 표시
        tokenStatusLabel.text = "토큰 인증: 재초기화 중..."
        tokenStatusLabel.textColor = .systemOrange
        
        appendLog("⚙️ 설정이 저장되었습니다. SDK 재초기화 중...")
        
        // 1.5초 후 SDK 상태 확인 (notification 못받은 경우 대비)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.checkSDKStatusIfNeeded()
        }
    }
}

// MARK: - UITableViewDataSource

extension MainViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if cart.isEmpty {
            return 1 // 빈 상태 메시지용
        }
        return cart.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CartCell", for: indexPath)
        
        if cart.isEmpty {
            cell.textLabel?.text = "카트가 비어있습니다"
            cell.textLabel?.textColor = .secondaryLabel
            cell.textLabel?.font = .systemFont(ofSize: 14)
            cell.selectionStyle = .none
        } else {
            let product = cart[indexPath.row]
            cell.textLabel?.numberOfLines = 2
            cell.textLabel?.font = .systemFont(ofSize: 13)
            cell.textLabel?.textColor = .label
            cell.textLabel?.text = """
            \(product.productName) (ID: \(product.productId))
            \(product.price)원 → \(product.discountPrice)원 | 수량: \(product.quantity)개
            """
            cell.selectionStyle = .default
        }
        
        return cell
    }
}

// MARK: - UITableViewDelegate

extension MainViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cart.isEmpty ? 50 : 60
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete && !cart.isEmpty {
            let product = cart[indexPath.row]
            cart.remove(at: indexPath.row)
            updateCartUI()
            appendLog("🗑️ \(product.productName) 카트에서 제거됨")
        }
    }
}

// MARK: - UITextFieldDelegate

extension MainViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

