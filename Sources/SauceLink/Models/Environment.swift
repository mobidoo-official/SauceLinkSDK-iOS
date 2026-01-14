import Foundation

/// SDK 환경 설정
/// stage, prod 환경에 따라 API 엔드포인트가 달라집니다
public enum Environment: String {
    case stage
    case prod
    
    /// 트래킹 API Base URL
    var baseURL: String {
        switch self {
        case .stage:
            return "https://stage.tracking.slink.im"
        case .prod:
            return "https://tracking.slink.im"
        }
    }
    
    /// 인증 API Base URL (웹 SDK와 동일한 엔드포인트 사용)
    var authBaseURL: String {
        switch self {
        case .stage:
            return "https://stage.api-user.sauceflex.com"
        case .prod:
            return "https://api-user.sauceflex.com"
        }
    }
}

