import Foundation

/// 로컬 저장소 관리자
/// clickId, sLink, sLinkEndDate 등을 UserDefaults에 저장/조회
final class StorageManager {
    
    // MARK: - Constants
    
    private enum Keys {
        static let clickId = "com.saucelink.tracker.clickId"
        static let sLink = "com.saucelink.tracker.sLink"
        static let sLinkEndDate = "com.saucelink.tracker.sLinkEndDate"
        static let sLinkT = "com.saucelink.tracker.sLinkT"
        static let firstAccess = "com.saucelink.tracker.firstAccess"
    }
    
    /// sLink 만료 기간 (7일)
    private let sLinkExpirationDays: TimeInterval = 7 * 24 * 60 * 60
    
    // MARK: - Private Properties
    
    private let userDefaults: UserDefaults
    
    // 메모리 캐시 (UserDefaults 실패 대비)
    private var memoryClickId: String?
    private var memorySLink: String?
    private var memorySLinkEndDate: TimeInterval?
    private var memorySLinkT: TimeInterval?
    
    // MARK: - Initialization
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    // MARK: - Click ID (영구 저장)
    
    /// clickId 조회 또는 생성
    /// 영구 저장되며 만료되지 않음
    /// - Returns: 디바이스 고유 UUID
    func getOrCreateClickId() -> String {
        // 메모리 캐시 확인
        if let cached = memoryClickId {
            return cached
        }
        
        // UserDefaults에서 조회
        if let stored = userDefaults.string(forKey: Keys.clickId) {
            memoryClickId = stored
            return stored
        }
        
        // 새로 생성
        let newClickId = UUID().uuidString
        saveClickId(newClickId)
        return newClickId
    }
    
    /// clickId 저장
    private func saveClickId(_ clickId: String) {
        memoryClickId = clickId
        
        do {
            userDefaults.set(clickId, forKey: Keys.clickId)
        } catch {
            Logger.error("Failed to save clickId: \(error.localizedDescription)")
        }
    }
    
    // MARK: - sLink 관리
    
    /// sLink 조회
    /// - Returns: 저장된 sLink (없으면 nil)
    func getSLink() -> String? {
        // 먼저 만료 확인
        if let endDate = getSLinkEndDate() {
            let currentTime = Date().timeIntervalSince1970
            if currentTime > endDate {
                // 만료됨 - 삭제
                clearSLink()
                return nil
            }
        }
        
        // 메모리 캐시 확인
        if let cached = memorySLink {
            return cached
        }
        
        // UserDefaults에서 조회
        let stored = userDefaults.string(forKey: Keys.sLink)
        memorySLink = stored
        return stored
    }
    
    /// sLinkEndDate 조회
    /// - Returns: sLink 만료 시간 (timestamp)
    func getSLinkEndDate() -> TimeInterval? {
        // 메모리 캐시 확인
        if let cached = memorySLinkEndDate {
            return cached
        }
        
        // UserDefaults에서 조회
        let stored = userDefaults.double(forKey: Keys.sLinkEndDate)
        if stored > 0 {
            memorySLinkEndDate = stored
            return stored
        }
        
        return nil
    }
    
    /// sLinkT 조회
    /// - Returns: 이벤트 기여기간 (timestamp)
    func getSLinkT() -> TimeInterval? {
        // 메모리 캐시 확인
        if let cached = memorySLinkT {
            return cached
        }
        
        // UserDefaults에서 조회
        let stored = userDefaults.double(forKey: Keys.sLinkT)
        if stored > 0 {
            memorySLinkT = stored
            return stored
        }
        
        return nil
    }
    
    /// sLink 저장
    /// endDate는 현재 시간 + 7일로 자동 설정
    /// - Parameters:
    ///   - sLink: 저장할 sLink 값
    ///   - sLinkT: 이벤트 기여기간 (선택)
    func saveSLink(_ sLink: String, sLinkT: TimeInterval? = nil) {
        let endDate = Date().timeIntervalSince1970 + sLinkExpirationDays
        
        // 메모리 캐시 업데이트
        memorySLink = sLink
        memorySLinkEndDate = endDate
        memorySLinkT = sLinkT
        
        // UserDefaults에 저장
        do {
            userDefaults.set(sLink, forKey: Keys.sLink)
            userDefaults.set(endDate, forKey: Keys.sLinkEndDate)
            
            if let sLinkT = sLinkT {
                userDefaults.set(sLinkT, forKey: Keys.sLinkT)
            }
            
            Logger.info("sLink saved: \(sLink), endDate: \(Date(timeIntervalSince1970: endDate))")
        } catch {
            Logger.error("Failed to save sLink: \(error.localizedDescription)")
        }
    }
    
    /// sLinkEndDate만 갱신 (7일로 리셋)
    func refreshSLinkEndDate() {
        let endDate = Date().timeIntervalSince1970 + sLinkExpirationDays
        
        // 메모리 캐시 업데이트
        memorySLinkEndDate = endDate
        
        // UserDefaults에 저장
        do {
            userDefaults.set(endDate, forKey: Keys.sLinkEndDate)
            Logger.info("sLinkEndDate refreshed: \(Date(timeIntervalSince1970: endDate))")
        } catch {
            Logger.error("Failed to refresh sLinkEndDate: \(error.localizedDescription)")
        }
    }
    
    /// sLink 삭제
    func clearSLink() {
        // 메모리 캐시 클리어
        memorySLink = nil
        memorySLinkEndDate = nil
        memorySLinkT = nil
        
        // UserDefaults에서 삭제
        userDefaults.removeObject(forKey: Keys.sLink)
        userDefaults.removeObject(forKey: Keys.sLinkEndDate)
        userDefaults.removeObject(forKey: Keys.sLinkT)
        
        Logger.info("sLink cleared")
    }
    
    // MARK: - First Access
    
    /// 최초 접속 여부 확인
    /// - Returns: 최초 접속이면 true
    func isFirstAccess() -> Bool {
        return !userDefaults.bool(forKey: Keys.firstAccess)
    }
    
    /// 최초 접속 완료 표시
    func markFirstAccessComplete() {
        userDefaults.set(true, forKey: Keys.firstAccess)
    }
    
    // MARK: - Debug
    
    /// 모든 저장 데이터 삭제 (디버그용)
    func clearAll() {
        memoryClickId = nil
        memorySLink = nil
        memorySLinkEndDate = nil
        memorySLinkT = nil
        
        userDefaults.removeObject(forKey: Keys.clickId)
        userDefaults.removeObject(forKey: Keys.sLink)
        userDefaults.removeObject(forKey: Keys.sLinkEndDate)
        userDefaults.removeObject(forKey: Keys.sLinkT)
        userDefaults.removeObject(forKey: Keys.firstAccess)
        
        Logger.info("All storage cleared")
    }
}

