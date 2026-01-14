import Foundation

/// 서버로 전송되는 트래킹 데이터
struct TrackingData: Encodable {

    /// 파트너 고유 ID (init 시 받은 값)
    let partner_unique_id: String

    /// 소스 링크 코드 (딥링크의 sLink 파라미터)
    let sauce_link_code: String?

    /// 쇼핑몰 호스트 이름 ("SAUCE" 고정)
    let shop_host_name: String

    /// 플랫폼 ("APP" 고정)
    let platform: String

    /// User Agent (iOS 기기 정보)
    let user_agent: String

    /// 유저 디바이스 (예: "iPhone 15 Pro")
    let user_device: String

    /// 유저 OS (예: "iOS 17.5.1")
    let user_os: String

    /// 클릭 ID (디바이스 고유 UUID)
    let click_id: String

    /// 요청 ID (이벤트 고유 식별자, UUID)
    let request_id: String

    /// 최초 접속 여부
    let first_access: Bool

    /// 이벤트 발생 일시 (ISO8601 형식, 밀리세컨드 포함)
    let event_date: String

    /// 이벤트 이름 (PRODUCT_DETAIL, ORDER_COMPLETE, ORDER_CANCEL)
    let event_name: String

    /// 주문 ID (ORDER_COMPLETE, ORDER_CANCEL에서만 사용)
    let order_id: String?

    /// 상품 정보 배열 (딕셔너리 형태로 직접 전달)
    let json: [[String: Any]]

    // MARK: - Custom Encoding

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(partner_unique_id, forKey: .partner_unique_id)
        try container.encodeIfPresent(sauce_link_code, forKey: .sauce_link_code)
        try container.encode(shop_host_name, forKey: .shop_host_name)
        try container.encode(platform, forKey: .platform)
        try container.encode(user_agent, forKey: .user_agent)
        try container.encode(user_device, forKey: .user_device)
        try container.encode(user_os, forKey: .user_os)
        try container.encode(click_id, forKey: .click_id)
        try container.encode(request_id, forKey: .request_id)
        try container.encode(first_access, forKey: .first_access)
        try container.encode(event_date, forKey: .event_date)
        try container.encode(event_name, forKey: .event_name)
        try container.encodeIfPresent(order_id, forKey: .order_id)

        // 딕셔너리 배열 직접 인코딩
        try container.encode(AnyCodable(json), forKey: .json)
    }

    private enum CodingKeys: String, CodingKey {
        case partner_unique_id, sauce_link_code, shop_host_name, platform
        case user_agent, user_device, user_os, click_id, request_id
        case first_access, event_date, event_name, order_id, json
    }
}

// MARK: - AnyCodable Helper

/// Any 타입을 인코딩하기 위한 헬퍼
private struct AnyCodable: Encodable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        if let array = value as? [[String: Any]] {
            try container.encode(array.map { DictionaryWrapper($0) })
        } else {
            try container.encodeNil()
        }
    }
}

private struct DictionaryWrapper: Encodable {
    let dict: [String: Any]

    init(_ dict: [String: Any]) {
        self.dict = dict
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicKey.self)

        for (key, value) in dict {
            let codingKey = DynamicKey(stringValue: key)!

            if let stringValue = value as? String {
                try container.encode(stringValue, forKey: codingKey)
            } else if let intValue = value as? Int {
                try container.encode(intValue, forKey: codingKey)
            } else if let doubleValue = value as? Double {
                try container.encode(doubleValue, forKey: codingKey)
            } else if let boolValue = value as? Bool {
                try container.encode(boolValue, forKey: codingKey)
            }
        }
    }

    private struct DynamicKey: CodingKey {
        var stringValue: String
        var intValue: Int?

        init?(stringValue: String) {
            self.stringValue = stringValue
        }

        init?(intValue: Int) {
            return nil
        }
    }
}
