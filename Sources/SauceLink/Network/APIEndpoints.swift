import Foundation

/// API 엔드포인트 관리
enum APIEndpoints {

    /// 토큰 인증 API
    /// POST /sauce-link/v1/sdk/auth
    case tokenValidation(token: String, partnerUniqueId: String)

    /// 트래킹 데이터 전송 API
    /// POST /
    case tracking

    /// 엔드포인트 경로
    var path: String {
        switch self {
        case .tokenValidation:
            return "/sauce-link/v1/sdk/auth"
        case .tracking:
            return "/"
        }
    }

    /// HTTP 메서드
    var method: String {
        switch self {
        case .tokenValidation:
            return "POST"
        case .tracking:
            return "POST"
        }
    }

    /// 전체 URL 생성
    /// - Parameter environment: 환경 설정
    /// - Returns: URL (생성 실패 시 nil)
    func url(for environment: Environment) -> URL? {
        let baseURL: String

        switch self {
        case .tokenValidation:
            baseURL = environment.authBaseURL
        case .tracking:
            baseURL = environment.baseURL
        }

        var components = URLComponents(string: baseURL)
        components?.path = path
        return components?.url
    }
}

