import Foundation
import UIKit

/// SauceLink SDK 메인 클래스
/// 싱글톤 패턴으로 앱 전역에서 사용
public final class SauceLink {
    
    // MARK: - Singleton
    
    /// 공유 인스턴스
    public static let shared = SauceLink()
    
    // MARK: - Public Properties
    
    /// SDK 초기화 완료 여부
    public private(set) var isInitialized: Bool = false
    
    /// 토큰 인증 성공 여부
    public private(set) var isTokenValid: Bool = false
    
    /// 마지막 인증 상태 코드 (200, 401 등)
    public private(set) var lastAuthStatusCode: Int = 0
    
    // MARK: - Public Methods
    
    /// SDK 현재 상태를 동기적으로 가져오기 (thread-safe)
    /// - Returns: (초기화 완료 여부, 토큰 유효 여부, 상태 코드)
    public func getAuthStatus() -> (isInitialized: Bool, isTokenValid: Bool, statusCode: Int) {
        var result: (Bool, Bool, Int) = (false, false, 0)
        serialQueue.sync {
            result = (self.isInitialized, self.isTokenValid, self.lastAuthStatusCode)
        }
        return result
    }
    
    // MARK: - Private Properties
    
    private var config: TrackerConfig?
    private var userData: UserData?
    private var currentDeepLinkURL: String?
    
    private let storageManager = StorageManager()
    private let networkManager = NetworkManager()
    private let deepLinkHandler = DeepLinkHandler()
    
    private let serialQueue = DispatchQueue(label: "com.saucelink.tracker.serial")
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public API
    
    /// SDK 초기화 및 토큰 인증 (Android 가이드 호환)
    /// - Parameters:
    ///   - partnerUniqueId: 파트너 고유 ID
    ///   - sdkToken: SDK 토큰
    ///   - environment: 환경 설정 (.dev, .stage, .prod)
    ///   - completion: 초기화 완료 콜백 (Result<Void, Error>)
    public func configure(
        partnerUniqueId: String,
        sdkToken: String,
        environment: Environment = .prod,
        completion: ((Result<Void, Error>) -> Void)? = nil
    ) {
        let config = TrackerConfig(
            partnerUniqueId: partnerUniqueId,
            token: sdkToken,
            environment: environment
        )
        
        serialQueue.async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async {
                    completion?(.failure(NSError(domain: "SauceLink", code: -1, userInfo: [NSLocalizedDescriptionKey: "SDK instance is nil"])))
                }
                return
            }
            
            do {
                try self.internalInitialize(config: config) { success in
                    if success {
                        DispatchQueue.main.async { completion?(.success(())) }
                    } else {
                        DispatchQueue.main.async {
                            completion?(.failure(NSError(domain: "SauceLink", code: 401, userInfo: [NSLocalizedDescriptionKey: "Token validation failed"])))
                        }
                    }
                }
            } catch {
                Logger.error("Configure failed: \(error.localizedDescription)")
                DispatchQueue.main.async { completion?(.failure(error)) }
            }
        }
    }
    
    /// SDK 초기화 (기존 메서드, 호환성 유지)
    @available(*, deprecated, message: "Use init(partnerUniqueId:sdkToken:environment:completion:) instead")
    public func initialize(config: TrackerConfig, completion: ((Bool) -> Void)? = nil) {
        serialQueue.async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async { completion?(false) }
                return
            }
            
            do {
                try self.internalInitialize(config: config, completion: completion)
            } catch {
                Logger.error("Initialize failed: \(error.localizedDescription)")
                DispatchQueue.main.async { completion?(false) }
            }
        }
    }
    
    /// 소스링크 트래킹 링크 업데이트 (Android 가이드 호환)
    /// - Parameters:
    ///   - slink: 앱스킴을 통해 전달된 slink 값
    ///   - slinkT: 앱스킴을 통해 전달된 slink의 타임스탬프 값
    public func updateSlink(_ slink: String?, _ slinkT: String?) {
        Logger.info("📥 [SDK] updateSlink() 호출됨")
        Logger.info("   입력 sLink: \(slink ?? "nil")")
        Logger.info("   입력 sLinkT: \(slinkT ?? "nil")")
        
        serialQueue.async { [weak self] in
            guard let self = self else { return }
            
            guard let slink = slink, !slink.isEmpty else {
                Logger.warning("⚠️ [SDK] sLink가 비어있거나 nil입니다")
                return
            }
            
            Logger.info("✅ [SDK] sLink 값 확인: '\(slink)'")
            
            do {
                // sLinkT를 TimeInterval로 변환
                var timeInterval: TimeInterval? = nil
                if let slinkTStr = slinkT, let timestamp = TimeInterval(slinkTStr) {
                    timeInterval = timestamp
                    Logger.info("📅 [SDK] sLinkT 변환 성공: \(timestamp) (날짜: \(Date(timeIntervalSince1970: timestamp)))")
                } else if slinkT != nil {
                    Logger.warning("⚠️ [SDK] sLinkT 변환 실패: '\(slinkT!)' (유효하지 않은 타임스탬프)")
                } else {
                    Logger.info("ℹ️ [SDK] sLinkT 없음 (선택사항)")
                }
                
                // 초기화 전이면 저장만 하고 리턴
                guard self.isInitialized, self.isTokenValid else {
                    Logger.info("⏳ [SDK] SDK 초기화 대기 중... sLink 임시 저장")
                    Logger.info("   저장할 sLink: '\(slink)'")
                    if let sLinkT = timeInterval {
                        Logger.info("   저장할 sLinkT: \(sLinkT)")
                    }
                    // 나중에 처리하기 위해 임시 저장
                    self.storageManager.saveSLink(slink, sLinkT: timeInterval)
                    Logger.info("✅ [SDK] sLink 임시 저장 완료 (초기화 후 처리 예정)")
                    return
                }
                
                Logger.info("✅ [SDK] SDK 초기화 완료됨, sLink 처리 시작")
                
                // sLinkT 유효성 검사 (기여기간 확인)
                if let sLinkT = timeInterval {
                    let currentTime = Date().timeIntervalSince1970
                    Logger.info("⏰ [SDK] sLinkT 유효성 검사:")
                    Logger.info("   sLinkT: \(sLinkT) (날짜: \(Date(timeIntervalSince1970: sLinkT)))")
                    Logger.info("   현재 시간: \(currentTime) (날짜: \(Date(timeIntervalSince1970: currentTime)))")
                    
                    // sLinkT가 현재 시간보다 이전이면 기여기간 만료
                    if sLinkT < currentTime {
                        Logger.warning("❌ [SDK] sLinkT 만료됨 (과거 시간), sLink 제거")
                        self.storageManager.clearSLink()
                        return
                    } else {
                        Logger.info("✅ [SDK] sLinkT 유효함 (미래 시간)")
                    }
                }
                
                // sLink 저장 로직
                Logger.info("💾 [SDK] sLink 저장 로직 실행: '\(slink)'")
                self.processSLink(newSLink: slink, sLinkT: timeInterval)
            } catch {
                Logger.error("❌ [SDK] UpdateSlink 실패: \(error.localizedDescription)")
            }
        }
    }
    
    /// 딥링크 URL 전체를 처리 (기존 메서드, 호환성 유지)
    @available(*, deprecated, message: "Use updateSlink(_:_:) instead")
    public func handleDeepLink(url: URL) {
        serialQueue.async { [weak self] in
            guard let self = self else { return }
            
            do {
                try self.internalHandleDeepLink(url: url)
            } catch {
                Logger.error("HandleDeepLink failed: \(error.localizedDescription)")
            }
        }
    }
    
    /// 상품 상세 페이지 조회 이벤트 (Android 가이드 호환)
    /// - Parameters:
    ///   - product: 상품 상세 정보
    ///   - completion: 트래킹 API 성공 여부 체크를 위한 콜백
    public func trackProductDetail(
        product: ProductDetailInfo,
        completion: ((Result<Void, Error>) -> Void)? = nil
    ) {
        let properties: [String: Any] = [
            "products": [product.toDictionary()]
        ]

        sendEvent("PRODUCT_DETAIL", properties: properties) { success, statusCode in
            if success {
                completion?(.success(()))
            } else {
                let error = NSError(
                    domain: "SauceLink",
                    code: statusCode ?? -1,
                    userInfo: [NSLocalizedDescriptionKey: "Track event failed with status code: \(statusCode ?? -1)"]
                )
                completion?(.failure(error))
            }
        }
    }
    
    /// 주문 완료 이벤트 (Android 가이드 호환)
    /// - Parameters:
    ///   - orderId: 주문번호
    ///   - products: 주문 상품 정보 리스트
    ///   - completion: 트래킹 API 성공 여부 체크를 위한 콜백
    public func trackOrderComplete(
        orderId: String,
        products: [OrderProductInfo],
        completion: ((Result<Void, Error>) -> Void)? = nil
    ) {
        let properties: [String: Any] = [
            "order_id": orderId,
            "products": products.map { $0.toDictionary() }
        ]

        sendEvent("ORDER_COMPLETE", properties: properties) { success, statusCode in
            if success {
                completion?(.success(()))
            } else {
                let error = NSError(
                    domain: "SauceLink",
                    code: statusCode ?? -1,
                    userInfo: [NSLocalizedDescriptionKey: "Track event failed with status code: \(statusCode ?? -1)"]
                )
                completion?(.failure(error))
            }
        }
    }

    /// 주문 취소 이벤트 (Android 가이드 호환)
    /// - Parameters:
    ///   - orderId: 주문번호
    ///   - products: 주문 상품 정보 리스트
    ///   - completion: 트래킹 API 성공 여부 체크를 위한 콜백
    public func trackOrderCancel(
        orderId: String,
        products: [OrderProductInfo],
        completion: ((Result<Void, Error>) -> Void)? = nil
    ) {
        let properties: [String: Any] = [
            "order_id": orderId,
            "products": products.map { $0.toDictionary() }
        ]

        sendEvent("ORDER_CANCEL", properties: properties) { success, statusCode in
            if success {
                completion?(.success(()))
            } else {
                let error = NSError(
                    domain: "SauceLink",
                    code: statusCode ?? -1,
                    userInfo: [NSLocalizedDescriptionKey: "Track event failed with status code: \(statusCode ?? -1)"]
                )
                completion?(.failure(error))
            }
        }
    }
    
    /// 장바구니 담기 이벤트
    /// - Parameters:
    ///   - products: 장바구니 상품 정보 리스트
    ///   - completion: 트래킹 API 성공 여부 체크를 위한 콜백
    public func trackAddToCart(
        products: [OrderProductInfo],
        completion: ((Result<Void, Error>) -> Void)? = nil
    ) {
        let properties: [String: Any] = [
            "product_list": products.map { $0.toDictionary() }
        ]

        sendEvent("ADD_TO_CART", properties: properties) { success, statusCode in
            if success {
                completion?(.success(()))
            } else {
                let error = NSError(
                    domain: "SauceLink",
                    code: statusCode ?? -1,
                    userInfo: [NSLocalizedDescriptionKey: "Track event failed with status code: \(statusCode ?? -1)"]
                )
                completion?(.failure(error))
            }
        }
    }

    /// 회원가입 이벤트
    /// - Parameter completion: 트래킹 API 성공 여부 체크를 위한 콜백
    public func trackSignUp(
        completion: ((Result<Void, Error>) -> Void)? = nil
    ) {
        sendEvent("SIGN_UP") { success, statusCode in
            if success {
                completion?(.success(()))
            } else {
                let error = NSError(
                    domain: "SauceLink",
                    code: statusCode ?? -1,
                    userInfo: [NSLocalizedDescriptionKey: "Track event failed with status code: \(statusCode ?? -1)"]
                )
                completion?(.failure(error))
            }
        }
    }

    /// 사용자 정보 설정
    /// - Parameter userData: 사용자 정보 객체
    public func setUserData(_ userData: UserData) {
        serialQueue.async { [weak self] in
            guard let self = self else { return }
            
            do {
                try self.internalSetUserData(userData)
            } catch {
                Logger.error("SetUserData failed: \(error.localizedDescription)")
            }
        }
    }
    
    /// 범용 이벤트 전송 (내부 사용 및 호환성)
    /// - Parameters:
    ///   - eventName: 이벤트 이름 (PRODUCT_DETAIL, ORDER_COMPLETE, ORDER_CANCEL 등)
    ///   - properties: 이벤트 속성 (products, order_id 등)
    ///   - completion: 전송 완료 콜백 (성공 여부, HTTP 상태 코드)
    public func sendEvent(_ eventName: String, properties: [String: Any]? = nil, completion: ((Bool, Int?) -> Void)? = nil) {
        serialQueue.async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async { completion?(false, nil) }
                return
            }
            
            do {
                try self.internalSendEvent(eventName, properties: properties, completion: completion)
            } catch {
                Logger.error("SendEvent failed: \(error.localizedDescription)")
                DispatchQueue.main.async { completion?(false, nil) }
            }
        }
    }
    
    // MARK: - Internal Methods
    
    private func internalInitialize(config: TrackerConfig, completion: ((Bool) -> Void)?) throws {
        self.config = config
        
        // clickId 확인 또는 생성 (영구 저장)
        _ = storageManager.getOrCreateClickId()
        
        // 토큰 인증 API 호출
        networkManager.validateToken(
            token: config.token,
            partnerUniqueId: config.partnerUniqueId,
            environment: config.environment
        ) { [weak self] result in
            guard let self = self else {
                DispatchQueue.main.async { completion?(false) }
                return
            }
            
            switch result {
            case .success:
                self.serialQueue.async {
                    self.isTokenValid = true
                    self.isInitialized = true
                    self.lastAuthStatusCode = 200
                    Logger.info("SDK initialized successfully")
                    
                    // 초기화 후 대기 중인 딥링크 처리
                    if let deepLinkURL = self.currentDeepLinkURL,
                       let url = URL(string: deepLinkURL) {
                        try? self.internalHandleDeepLink(url: url)
                    }
                    
                    DispatchQueue.main.async { completion?(true) }
                }
                
            case .failure(let error):
                self.serialQueue.async {
                    self.isTokenValid = false
                    self.isInitialized = false
                    // 에러 코드 추출 (401 등)
                    self.lastAuthStatusCode = (error as NSError).code
                    Logger.error("Token validation failed: \(error.localizedDescription)")
                    DispatchQueue.main.async { completion?(false) }
                }
            }
        }
    }
    
    private func internalHandleDeepLink(url: URL) throws {
        currentDeepLinkURL = url.absoluteString
        
        // 초기화 전이면 저장만 하고 리턴
        guard isInitialized, isTokenValid else {
            Logger.info("SDK not initialized yet, deep link will be processed after initialization")
            return
        }
        
        // 딥링크에서 sLink, sLinkT 파싱
        let deepLinkData = deepLinkHandler.parse(url: url)
        
        guard let sLink = deepLinkData.sLink else {
            Logger.info("No sLink found in deep link")
            return
        }
        
        // sLinkT 유효성 검사 (기여기간 확인)
        if let sLinkT = deepLinkData.sLinkT {
            let currentTime = Date().timeIntervalSince1970
            
            // sLinkT가 현재 시간보다 이전이면 기여기간 만료
            if sLinkT < currentTime {
                Logger.info("sLinkT expired, removing sLink")
                storageManager.clearSLink()
                return
            }
        }
        
        // sLink 저장 로직
        processSLink(newSLink: sLink, sLinkT: deepLinkData.sLinkT)
    }
    
    private func processSLink(newSLink: String, sLinkT: TimeInterval?) {
        let currentTime = Date().timeIntervalSince1970
        
        Logger.info("🔄 [SDK] processSLink() 실행")
        Logger.info("   새 sLink: '\(newSLink)'")
        if let sLinkT = sLinkT {
            Logger.info("   새 sLinkT: \(sLinkT)")
        }
        
        // 기존 sLink 정보 가져오기
        let existingSLink = storageManager.getSLink()
        let existingEndDate = storageManager.getSLinkEndDate()
        
        Logger.info("📦 기존 sLink 정보:")
        Logger.info("   기존 sLink: \(existingSLink ?? "nil")")
        if let existingEndDate = existingEndDate {
            Logger.info("   기존 endDate: \(existingEndDate) (날짜: \(Date(timeIntervalSince1970: existingEndDate)))")
            Logger.info("   현재 시간: \(currentTime) (날짜: \(Date(timeIntervalSince1970: currentTime)))")
        } else {
            Logger.info("   기존 endDate: nil")
        }
        
        if let existingEndDate = existingEndDate {
            // endDate가 지났는지 확인
            if currentTime > existingEndDate {
                // 기존 sLink 만료됨 - 새로 저장
                Logger.info("⏰ [SDK] 기존 sLink 만료됨 (endDate 지남), 새 sLink 저장")
                storageManager.saveSLink(newSLink, sLinkT: sLinkT)
                Logger.info("✅ [SDK] 새 sLink 저장 완료: '\(newSLink)'")
            } else if existingSLink != newSLink {
                // 다른 sLink - 기존 것 삭제하고 새로 저장
                Logger.info("🔄 [SDK] 다른 sLink 수신됨 (기존: '\(existingSLink ?? "nil")', 새: '\(newSLink)')")
                Logger.info("   기존 sLink 삭제 후 새 sLink 저장")
                storageManager.saveSLink(newSLink, sLinkT: sLinkT)
                Logger.info("✅ [SDK] 새 sLink 저장 완료: '\(newSLink)'")
            } else {
                // 같은 sLink - endDate만 갱신
                Logger.info("✅ [SDK] 동일한 sLink 수신됨 ('\(newSLink)'), endDate만 갱신")
                storageManager.refreshSLinkEndDate()
                Logger.info("✅ [SDK] endDate 갱신 완료")
            }
        } else {
            // 기존 sLink 없음 - 새로 저장
            Logger.info("📝 [SDK] 기존 sLink 없음, 새 sLink 저장")
            storageManager.saveSLink(newSLink, sLinkT: sLinkT)
            Logger.info("✅ [SDK] 새 sLink 저장 완료: '\(newSLink)'")
        }
        
        // 최종 저장된 sLink 확인
        let savedSLink = storageManager.getSLink()
        Logger.info("💾 [SDK] 최종 저장된 sLink: '\(savedSLink ?? "nil")'")
    }
    
    private func internalSetUserData(_ userData: UserData) throws {
        // 기존 userData와 병합
        if let existing = self.userData {
            self.userData = existing.merged(with: userData)
        } else {
            self.userData = userData
        }
        
        Logger.info("UserData updated: \(String(describing: self.userData?.userId))")
    }
    
    private func internalSendEvent(_ eventName: String, properties: [String: Any]?, completion: ((Bool, Int?) -> Void)?) throws {
        // SDK 초기화 및 토큰 유효성 확인
        guard isInitialized, isTokenValid else {
            Logger.warning("SDK not initialized or token invalid, event ignored")
            DispatchQueue.main.async { completion?(false, nil) }
            return
        }
        
        guard let config = self.config else {
            Logger.warning("Config not set, event ignored")
            DispatchQueue.main.async { completion?(false, nil) }
            return
        }
        
        // sLink 필수 체크
        guard let sLink = storageManager.getSLink(), !sLink.isEmpty else {
            Logger.warning("No sLink available, event ignored. Please call updateSlink() first.")
            DispatchQueue.main.async { completion?(false, nil) }
            return
        }
        
        // 트래킹 데이터 구성
        let trackingData = buildTrackingData(
            eventName: eventName,
            properties: properties,
            config: config
        )
        
        // 서버로 전송
        networkManager.sendTrackingData(trackingData, environment: config.environment) { result in
            switch result {
            case .success:
                Logger.info("Event sent successfully: \(eventName)")
                DispatchQueue.main.async { completion?(true, 200) }
            case .failure(let error):
                Logger.error("Event send failed: \(error.localizedDescription)")
                var statusCode: Int? = nil
                if case .httpError(let code, _, _) = error {
                    statusCode = code
                }
                DispatchQueue.main.async { completion?(false, statusCode) }
            }
        }
    }
    
    private func buildTrackingData(
        eventName: String,
        properties: [String: Any]?,
        config: TrackerConfig
    ) -> TrackingData {
        let clickId = storageManager.getOrCreateClickId()
        let sLink = storageManager.getSLink()
        let isFirstAccess = storageManager.isFirstAccess()

        // first_access 플래그 업데이트
        if isFirstAccess {
            storageManager.markFirstAccessComplete()
        }

        // products 딕셔너리 배열 직접 사용 (이미 올바른 형식)
        let products = properties?["products"] as? [[String: Any]] ?? []

        // order_id 파싱
        let orderId = properties?["order_id"] as? String

        // ISO8601 날짜 포맷 (밀리세컨드 포함)
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let eventDate = dateFormatter.string(from: Date())

        return TrackingData(
            partner_unique_id: config.partnerUniqueId,
            sauce_link_code: sLink,
            shop_host_name: "SAUCE",
            platform: "APP",
            user_agent: DeviceInfo.userAgent,
            user_device: DeviceInfo.deviceModelName,
            user_os: "iOS \(DeviceInfo.osVersion)",
            click_id: clickId,
            request_id: UUID().uuidString,
            first_access: isFirstAccess,
            event_date: eventDate,
            event_name: eventName,
            order_id: orderId,
            json: products
        )
    }
}

