import Foundation

/// 로컬 저장소 관리자
/// clickId, sLink, sLinkEndDate 등을 UserDefaults에 저장/조회
final class StorageManager {

    // MARK: - Constants

    private enum Keys {
        static let clickId = "com.saucelink.tracker.clickId"
        static let sLink = "com.saucelink.tracker.sLink"
        static let sLinkEndDate = "com.saucelink.tracker.sLinkEndDate"
        static let sLinkSavedAt = "com.saucelink.tracker.sLinkSavedAt"
        static let firstAccess = "com.saucelink.tracker.firstAccess"
    }

    // MARK: - Private Properties

    private let userDefaults: UserDefaults
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yy.MM.dd HH:mm"
        return f
    }()

    // 메모리 캐시 (UserDefaults 실패 대비)
    private var memoryClickId: String?
    private var memorySLink: String?
    private var memorySLinkEndDate: TimeInterval?
    private var memorySLinkSavedAt: TimeInterval?

    // MARK: - Initialization

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    // MARK: - Click ID (영구 저장)

    /// clickId 조회 또는 생성
    /// 영구 저장되며 만료되지 않음
    /// - Returns: 디바이스 고유 UUID
    func getOrCreateClickId() -> String {
        if let cached = memoryClickId { return cached }

        if let stored = userDefaults.string(forKey: Keys.clickId) {
            memoryClickId = stored
            return stored
        }

        let newClickId = UUID().uuidString
        saveClickId(newClickId)
        return newClickId
    }

    private func saveClickId(_ clickId: String) {
        memoryClickId = clickId
        userDefaults.set(clickId, forKey: Keys.clickId)
    }

    // MARK: - sLink 관리

    /// sLink 조회
    /// - Returns: 저장된 sLink (없으면 nil)
    func getSLink() -> String? {
        if let endDate = getSLinkEndDate() {
            let currentTime = Date().timeIntervalSince1970
            if currentTime > endDate {
                logSLinkStatus(isExpired: true)
                clearSLink()
                return nil
            }
        }

        if let cached = memorySLink { return cached }

        let stored = userDefaults.string(forKey: Keys.sLink)
        memorySLink = stored
        return stored
    }

    /// sLinkEndDate 조회
    func getSLinkEndDate() -> TimeInterval? {
        if let cached = memorySLinkEndDate { return cached }

        let stored = userDefaults.double(forKey: Keys.sLinkEndDate)
        if stored > 0 {
            memorySLinkEndDate = stored
            return stored
        }
        return nil
    }

    /// sLink 유입 시간 조회
    func getSLinkSavedAt() -> TimeInterval? {
        if let cached = memorySLinkSavedAt { return cached }

        let stored = userDefaults.double(forKey: Keys.sLinkSavedAt)
        if stored > 0 {
            memorySLinkSavedAt = stored
            return stored
        }
        return nil
    }

    /// sLink 저장
    /// - Parameters:
    ///   - sLink: 저장할 sLink 값
    ///   - retentionInterval: 서버에서 받은 쿠키 유지 기간 (초)
    func saveSLink(_ sLink: String, retentionInterval: TimeInterval) {
        let now = Date().timeIntervalSince1970
        let endDate = now + retentionInterval

        memorySLink = sLink
        memorySLinkEndDate = endDate
        memorySLinkSavedAt = now

        userDefaults.set(sLink, forKey: Keys.sLink)
        userDefaults.set(endDate, forKey: Keys.sLinkEndDate)
        userDefaults.set(now, forKey: Keys.sLinkSavedAt)

        logSLinkStatus(savedAt: now, endDate: endDate, isExpired: false)
    }

    /// sLinkEndDate만 갱신 (재진입 시)
    /// - Parameter retentionInterval: 서버에서 받은 쿠키 유지 기간 (초)
    func refreshSLinkEndDate(retentionInterval: TimeInterval) {
        let now = Date().timeIntervalSince1970
        let endDate = now + retentionInterval

        memorySLinkEndDate = endDate
        memorySLinkSavedAt = now

        userDefaults.set(endDate, forKey: Keys.sLinkEndDate)
        userDefaults.set(now, forKey: Keys.sLinkSavedAt)

        logSLinkStatus(savedAt: now, endDate: endDate, isExpired: false)
    }

    /// sLink 상태 로그 출력
    func logSLinkStatus(savedAt: TimeInterval? = nil, endDate: TimeInterval? = nil, isExpired: Bool? = nil) {
        let actualSavedAt = savedAt ?? getSLinkSavedAt()
        let actualEndDate = endDate ?? getSLinkEndDate()
        let currentTime = Date().timeIntervalSince1970
        let actualIsExpired = isExpired ?? (actualEndDate.map { currentTime > $0 } ?? true)

        let savedAtStr = actualSavedAt.map { dateFormatter.string(from: Date(timeIntervalSince1970: $0)) } ?? "-"
        let endDateStr = actualEndDate.map { dateFormatter.string(from: Date(timeIntervalSince1970: $0)) } ?? "-"

        Logger.info("📌 [sLink 상태]")
        Logger.info("   유입시간 : \(savedAtStr)")
        Logger.info("   유효기간 : \(endDateStr)")
        Logger.info("   만료여부 : \(actualIsExpired ? "Y" : "N")")
    }

    /// sLink 삭제
    func clearSLink() {
        memorySLink = nil
        memorySLinkEndDate = nil
        memorySLinkSavedAt = nil

        userDefaults.removeObject(forKey: Keys.sLink)
        userDefaults.removeObject(forKey: Keys.sLinkEndDate)
        userDefaults.removeObject(forKey: Keys.sLinkSavedAt)

        Logger.info("sLink cleared")
    }

    // MARK: - First Access

    func isFirstAccess() -> Bool {
        return !userDefaults.bool(forKey: Keys.firstAccess)
    }

    func markFirstAccessComplete() {
        userDefaults.set(true, forKey: Keys.firstAccess)
    }

    // MARK: - Debug

    func clearAll() {
        memoryClickId = nil
        memorySLink = nil
        memorySLinkEndDate = nil
        memorySLinkSavedAt = nil

        userDefaults.removeObject(forKey: Keys.clickId)
        userDefaults.removeObject(forKey: Keys.sLink)
        userDefaults.removeObject(forKey: Keys.sLinkEndDate)
        userDefaults.removeObject(forKey: Keys.sLinkSavedAt)
        userDefaults.removeObject(forKey: Keys.firstAccess)

        Logger.info("All storage cleared")
    }
}
