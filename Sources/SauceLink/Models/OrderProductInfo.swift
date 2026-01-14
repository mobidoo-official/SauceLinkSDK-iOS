import Foundation

/// 주문 상품 정보 (ORDER_COMPLETE, ORDER_CANCEL 이벤트용)
public struct OrderProductInfo: Encodable {

    /// 상품 코드
    public let product_id: String

    /// 상품명
    public let product_name: String

    /// 상품 가격
    public let price: String

    /// 상품 할인가격
    public let discount_price: String

    /// 상품 수량
    public let quantity: Int

    /// OrderProductInfo 초기화
    /// - Parameters:
    ///   - product_id: 상품 코드
    ///   - product_name: 상품명
    ///   - price: 상품 가격
    ///   - discount_price: 상품 할인가격
    ///   - quantity: 상품 수량
    public init(
        product_id: String,
        product_name: String,
        price: String,
        discount_price: String,
        quantity: Int
    ) {
        self.product_id = product_id
        self.product_name = product_name
        self.price = price
        self.discount_price = discount_price
        self.quantity = quantity
    }

    /// Dictionary에서 OrderProductInfo 생성
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
            self.discount_price = self.price
        }

        if let qty = dict["quantity"] as? Int {
            self.quantity = qty
        } else if let qtyNumber = dict["quantity"] as? NSNumber {
            self.quantity = qtyNumber.intValue
        } else {
            self.quantity = 1
        }
    }

    /// OrderProductInfo를 Dictionary로 변환
    public func toDictionary() -> [String: Any] {
        return [
            "product_id": product_id,
            "product_name": product_name,
            "price": price,
            "discount_price": discount_price,
            "quantity": quantity
        ]
    }
}
