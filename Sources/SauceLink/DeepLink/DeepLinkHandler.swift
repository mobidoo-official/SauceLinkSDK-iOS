import Foundation

/// 딥링크 파싱 결과
struct DeepLinkData {
    /// sLink 코드
    let sLink: String?
    /// 전체 딥링크 URL
    let fullURL: String
}

/// 딥링크 처리기
/// sLink 파라미터를 파싱
final class DeepLinkHandler {

    // MARK: - Constants

    private enum QueryParams {
        static let sLink = "sLink"
    }

    // MARK: - Public Methods

    /// URL에서 sLink 파싱
    /// - Parameter url: 딥링크 URL
    /// - Returns: 파싱된 DeepLinkData
    func parse(url: URL) -> DeepLinkData {
        let fullURL = url.absoluteString

        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            Logger.warning("Failed to parse URL components: \(fullURL)")
            return DeepLinkData(sLink: nil, fullURL: fullURL)
        }

        let queryItems = components.queryItems ?? []
        var sLink: String?

        for item in queryItems {
            if item.name == QueryParams.sLink {
                sLink = item.value
            }
        }

        if let sLink = sLink {
            Logger.info("Parsed deep link - sLink: \(sLink)")
        }

        return DeepLinkData(sLink: sLink, fullURL: fullURL)
    }

    /// Universal Link에서 sLink 파라미터 추출
    func parseUniversalLink(url: URL) -> DeepLinkData {
        return parse(url: url)
    }
}

