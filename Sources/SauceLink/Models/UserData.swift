import Foundation

/// 사용자 정보
public struct UserData {
    
    /// 사용자 ID (고객사 사이트의 고객 ID)
    public let userId: String?
    
    /// UserData 초기화
    /// - Parameter userId: 사용자 ID (선택사항)
    public init(userId: String? = nil) {
        self.userId = userId
    }
    
    /// 다른 UserData와 병합
    /// 새로운 값이 nil이 아니면 덮어씁니다
    /// - Parameter other: 병합할 UserData
    /// - Returns: 병합된 새로운 UserData
    func merged(with other: UserData) -> UserData {
        return UserData(
            userId: other.userId ?? self.userId
        )
    }
}

