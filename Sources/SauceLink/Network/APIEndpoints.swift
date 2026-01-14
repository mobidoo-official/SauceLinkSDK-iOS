import Foundation

/// API 엔드포인트 관리
enum APIEndpoints {
    
    /// 토큰 인증 API
    /// GET /v1/sauce-link/auth/sdk/validation
    case tokenValidation(token: String, partnerUniqueId: String)
    
    /// 트래킹 데이터 전송 API
    /// POST /
    case tracking
    
    /// 엔드포인트 경로
    var path: String {
        switch self {
        case .tokenValidation:
            return "/v1/sauce-link/auth/sdk/validation"
        case .tracking:
            return "/"
        }
    }
    
    /// HTTP 메서드
    var method: String {
        switch self {
        case .tokenValidation:
            return "GET"
        case .tracking:
            return "POST"
        }
    }
    
    /// 쿼리 파라미터
    var queryItems: [URLQueryItem]? {
        switch self {
        case .tokenValidation(let token, let partnerUniqueId):
            return [
                URLQueryItem(name: "sauceLinkSdkToken", value: token),
                URLQueryItem(name: "partnerUniqueId", value: partnerUniqueId)
            ]
        case .tracking:
            return nil
        }
    }
    
    /// 전체 URL 생성
    /// - Parameter environment: 환경 설정
    /// - Returns: URL (생성 실패 시 nil)
    func url(for environment: Environment) -> URL? {
        let baseURL: String
        
        // 토큰 인증은 authBaseURL, 트래킹은 baseURL 사용
        switch self {
        case .tokenValidation:
            baseURL = environment.authBaseURL
        case .tracking:
            baseURL = environment.baseURL
        }
        
        var components = URLComponents(string: baseURL)
        components?.path = path
        components?.queryItems = queryItems
        return components?.url
    }
}

