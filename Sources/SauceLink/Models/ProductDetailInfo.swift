import Foundation

/// 상품 상세 정보 (PRODUCT_DETAIL 이벤트용)
public struct ProductDetailInfo: Encodable {

    /// 상품 코드
    public let product_id: String

    /// 상품명
    public let product_name: String

    /// 상품 가격
    public let price: String

    /// 상품 할인가격 (선택)
    public let discount_price: String?

    /// ProductDetailInfo 초기화
    /// - Parameters:
    ///   - product_id: 상품 코드
    ///   - product_name: 상품명
    ///   - price: 상품 가격
    ///   - discount_price: 상품 할인가격 (선택)
    public init(
        product_id: String,
        product_name: String,
        price: String,
        discount_price: String? = nil
    ) {
        self.product_id = product_id
        self.product_name = product_name
        self.price = price
        self.discount_price = discount_price
    }

    /// Dictionary에서 ProductDetailInfo 생성
    init?(from dict: [String: Any]) {
        guard let productId = dict["product_id"] as? String,
              let productName = dict["product_name"] as? String else {
            return nil
        }

        self.product_id = productId
        self.product_name = productName

        if let priceString = dict["price"] as? String {
            self.price = priceString
        } else if let priceNumber = dict["price"] as? NSNumber {
            self.price = priceNumber.stringValue
        } else {
            self.price = "0"
        }

        if let discountString = dict["discount_price"] as? String {
            self.discount_price = discountString
        } else if let discountNumber = dict["discount_price"] as? NSNumber {
            self.discount_price = discountNumber.stringValue
        } else {
            self.discount_price = nil
        }
    }

    /// ProductDetailInfo를 Dictionary로 변환
    public func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "product_id": product_id,
            "product_name": product_name,
            "price": price
        ]
        if let discount_price = discount_price {
            dict["discount_price"] = discount_price
        }
        return dict
    }
}
