import Foundation

/// SDK 초기화 설정
public struct TrackerConfig {
    
    /// 고객사 파트너 고유 ID
    public let partnerUniqueId: String
    
    /// SDK 인증 토큰 (sla_xxx 형식, 32자)
    public let token: String
    
    /// 환경 설정 (dev, stage, prod)
    public let environment: Environment
    
    /// TrackerConfig 초기화
    /// - Parameters:
    ///   - partnerUniqueId: 고객사 파트너 고유 ID
    ///   - token: SDK 인증 토큰 (sla_xxx 형식)
    ///   - environment: 환경 설정 (기본값: .prod)
    public init(
        partnerUniqueId: String,
        token: String,
        environment: Environment = .prod
    ) {
        self.partnerUniqueId = partnerUniqueId
        self.token = token
        self.environment = environment
    }
}

