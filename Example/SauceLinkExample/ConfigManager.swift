import Foundation
import SauceLinkSDK

/// 테스트 앱 설정 관리자
///
/// 환경 변경 방법:
/// ```swift
/// // ConfigManager.swift 파일에서 기본값 변경
/// ConfigManager.shared.environment = .dev   // 또는 .stage, .prod
/// 
/// // 또는 메서드 사용
/// ConfigManager.shared.setEnvironment(.stage)
/// ```
///
/// 이 한 곳만 변경하면 AppDelegate와 MainViewController에 자동 적용됩니다.
class ConfigManager {
    
    static let shared = ConfigManager()
    
    private let userDefaults = UserDefaults.standard
    
    // MARK: - Keys
    
    private enum Keys {
        static let partnerUniqueId = "test.partnerUniqueId"
        static let token = "test.token"
        static let defaultProductId = "test.defaultProductId"
        static let defaultOrderId = "test.defaultOrderId"
        static let productName = "test.productName"
        static let productPrice = "test.productPrice"
        static let productDiscountPrice = "test.productDiscountPrice"
        static let slink = "test.slink"
        static let slinkT = "test.slinkT"
        static let userId = "test.userId"
        static let environment = "test.environment"
    }
    
    // MARK: - Properties
    
    var partnerUniqueId: String {
        get { userDefaults.string(forKey: Keys.partnerUniqueId) ?? "" }
        set { userDefaults.set(newValue, forKey: Keys.partnerUniqueId) }
    }
    
    var token: String {
        get { userDefaults.string(forKey: Keys.token) ?? "" }
        set { userDefaults.set(newValue, forKey: Keys.token) }
    }
    
    var defaultProductId: String {
        get { userDefaults.string(forKey: Keys.defaultProductId) ?? "" }
        set { userDefaults.set(newValue, forKey: Keys.defaultProductId) }
    }
    
    var defaultOrderId: String {
        get { userDefaults.string(forKey: Keys.defaultOrderId) ?? "" }
        set { userDefaults.set(newValue, forKey: Keys.defaultOrderId) }
    }
    
    var productName: String {
        get { userDefaults.string(forKey: Keys.productName) ?? "" }
        set { userDefaults.set(newValue, forKey: Keys.productName) }
    }
    
    var productPrice: String {
        get { userDefaults.string(forKey: Keys.productPrice) ?? "" }
        set { userDefaults.set(newValue, forKey: Keys.productPrice) }
    }
    
    var productDiscountPrice: String {
        get { userDefaults.string(forKey: Keys.productDiscountPrice) ?? "" }
        set { userDefaults.set(newValue, forKey: Keys.productDiscountPrice) }
    }
    
    var slink: String {
        get { userDefaults.string(forKey: Keys.slink) ?? "" }
        set { userDefaults.set(newValue, forKey: Keys.slink) }
    }
    
    var slinkT: String {
        get { userDefaults.string(forKey: Keys.slinkT) ?? "" }
        set { userDefaults.set(newValue, forKey: Keys.slinkT) }
    }
    
    var userId: String {
        get { userDefaults.string(forKey: Keys.userId) ?? "" }
        set { userDefaults.set(newValue, forKey: Keys.userId) }
    }
    
    var environment: Environment {
        get {
            if let rawValue = userDefaults.string(forKey: Keys.environment) {
                return Environment(rawValue: rawValue) ?? .stage
            }
            return .stage // 기본값: Stage 환경
        }
        set {
            userDefaults.set(newValue.rawValue, forKey: Keys.environment)
        }
    }
    
    var environmentDisplayName: String {
        switch environment {
        case .stage: return "Stage"
        case .prod: return "Prod"
        }
    }
    
    // MARK: - Methods
    
    /// 환경 변경 (쉬운 접근)
    func setEnvironment(_ env: Environment) {
        self.environment = env
    }
    
    /// 설정 저장
    func saveConfig(
        partnerUniqueId: String,
        token: String,
        defaultProductId: String,
        defaultOrderId: String,
        productName: String,
        productPrice: String,
        productDiscountPrice: String,
        slink: String,
        slinkT: String
    ) {
        self.partnerUniqueId = partnerUniqueId
        self.token = token
        self.defaultProductId = defaultProductId
        self.defaultOrderId = defaultOrderId
        self.productName = productName
        self.productPrice = productPrice
        self.productDiscountPrice = productDiscountPrice
        self.slink = slink
        self.slinkT = slinkT
    }
    
    /// 설정 초기화 여부
    var isConfigured: Bool {
        return !partnerUniqueId.isEmpty && !token.isEmpty
    }
    
    /// 모든 설정 삭제
    func clearAll() {
        userDefaults.removeObject(forKey: Keys.partnerUniqueId)
        userDefaults.removeObject(forKey: Keys.token)
        userDefaults.removeObject(forKey: Keys.defaultProductId)
        userDefaults.removeObject(forKey: Keys.defaultOrderId)
        userDefaults.removeObject(forKey: Keys.productName)
        userDefaults.removeObject(forKey: Keys.productPrice)
        userDefaults.removeObject(forKey: Keys.productDiscountPrice)
        userDefaults.removeObject(forKey: Keys.slink)
        userDefaults.removeObject(forKey: Keys.slinkT)
        userDefaults.removeObject(forKey: Keys.userId)
        userDefaults.removeObject(forKey: Keys.environment)
    }
}

