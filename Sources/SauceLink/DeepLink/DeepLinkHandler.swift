import Foundation

/// 딥링크 파싱 결과
struct DeepLinkData {
    /// sLink 코드
    let sLink: String?
    /// sLinkT 이벤트 기여기간 (timestamp)
    let sLinkT: TimeInterval?
    /// 전체 딥링크 URL
    let fullURL: String
}

/// 딥링크 처리기
/// sLink, sLinkT 파라미터를 파싱하고 유효성을 검증
final class DeepLinkHandler {
    
    // MARK: - Constants
    
    private enum QueryParams {
        static let sLink = "sLink"
        static let sLinkT = "sLinkT"
    }
    
    // MARK: - Public Methods
    
    /// URL에서 sLink, sLinkT 파싱
    /// - Parameter url: 딥링크 URL
    /// - Returns: 파싱된 DeepLinkData
    func parse(url: URL) -> DeepLinkData {
        let fullURL = url.absoluteString
        
        // URLComponents로 안전하게 파싱
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            Logger.warning("Failed to parse URL components: \(fullURL)")
            return DeepLinkData(sLink: nil, sLinkT: nil, fullURL: fullURL)
        }
        
        // 쿼리 파라미터 추출
        let queryItems = components.queryItems ?? []
        
        var sLink: String?
        var sLinkT: TimeInterval?
        
        for item in queryItems {
            switch item.name {
            case QueryParams.sLink:
                sLink = item.value
                
            case QueryParams.sLinkT:
                if let value = item.value, let timestamp = TimeInterval(value) {
                    sLinkT = timestamp
                }
                
            default:
                break
            }
        }
        
        if let sLink = sLink {
            Logger.info("Parsed deep link - sLink: \(sLink), sLinkT: \(String(describing: sLinkT))")
        }
        
        return DeepLinkData(sLink: sLink, sLinkT: sLinkT, fullURL: fullURL)
    }
    
    /// sLinkT가 유효한지 확인 (현재 시간 이후인지)
    /// - Parameter sLinkT: 이벤트 기여기간 timestamp
    /// - Returns: 유효하면 true
    func isValidSLinkT(_ sLinkT: TimeInterval?) -> Bool {
        guard let sLinkT = sLinkT else {
            // sLinkT가 없으면 유효한 것으로 처리
            return true
        }
        
        let currentTime = Date().timeIntervalSince1970
        return sLinkT >= currentTime
    }
    
    /// Universal Link에서 sLink 파라미터 추출
    /// - Parameter url: Universal Link URL
    /// - Returns: 파싱된 DeepLinkData
    func parseUniversalLink(url: URL) -> DeepLinkData {
        // Universal Link도 동일한 방식으로 처리
        return parse(url: url)
    }
}

