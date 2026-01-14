import XCTest
@testable import SauceLink

final class SauceLinkTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testTrackerSharedInstance() {
        let tracker1 = SauceLink.shared
        let tracker2 = SauceLink.shared
        XCTAssertTrue(tracker1 === tracker2, "Shared instance should be singleton")
    }
    
    func testEnvironmentBaseURL() {
        XCTAssertEqual(Environment.dev.baseURL, "https://dev.tracking.slink.im")
        XCTAssertEqual(Environment.stage.baseURL, "https://stage.tracking.slink.im")
        XCTAssertEqual(Environment.prod.baseURL, "https://tracking.slink.im")
    }
    
    func testProductInfoParsing() {
        let dict: [String: Any] = [
            "product_id": "test-id",
            "product_name": "Test Product",
            "price": 100,
            "discount_price": 90,
            "quantity": 2,
            "currency": "KRW"
        ]
        
        let product = ProductInfo(from: dict)
        XCTAssertNotNil(product)
        XCTAssertEqual(product?.product_id, "test-id")
        XCTAssertEqual(product?.product_name, "Test Product")
        XCTAssertEqual(product?.price, "100")
        XCTAssertEqual(product?.discount_price, "90")
        XCTAssertEqual(product?.quantity, 2)
        XCTAssertEqual(product?.currency, "KRW")
    }
    
    func testUserDataMerge() {
        let userData1 = UserData(userId: "user1")
        let userData2 = UserData(userId: "user2")
        
        let merged = userData1.merged(with: userData2)
        XCTAssertEqual(merged.userId, "user2")
    }
    
    func testDeepLinkParsing() {
        let handler = DeepLinkHandler()
        
        // sLink와 sLinkT가 있는 딥링크
        let url = URL(string: "myapp://product?sLink=abc123&sLinkT=1735689600")!
        let result = handler.parse(url: url)
        
        XCTAssertEqual(result.sLink, "abc123")
        XCTAssertEqual(result.sLinkT, 1735689600)
    }
    
    func testDeepLinkParsingWithoutParams() {
        let handler = DeepLinkHandler()
        
        // 파라미터 없는 딥링크
        let url = URL(string: "myapp://product")!
        let result = handler.parse(url: url)
        
        XCTAssertNil(result.sLink)
        XCTAssertNil(result.sLinkT)
    }
}
