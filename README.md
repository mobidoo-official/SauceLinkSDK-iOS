# SauceLinkSDK iOS

SauceLinkSDK는 iOS 앱에서 사용자 행동을 추적하고 SauceLink 서버로 이벤트 데이터를 전송하는 SDK입니다.

## 요구 사항

- iOS 14.0+
- Swift 5.5+
- Xcode 13.0+

## 설치

### Swift Package Manager (SPM)

Xcode에서:
1. File > Add Package Dependencies... 선택
2. URL 입력: `https://github.com/mobidoo-official/SauceLinkSDK-iOS.git`
3. "Add Package" 클릭

### CocoaPods

`Podfile`에 다음을 추가하세요:

```ruby
pod 'SauceLinkSDK'
```

```bash
pod install
```

> **Note**: Xcode 16 이상에서 빌드 에러 발생 시, Build Settings에서 `ENABLE_USER_SCRIPT_SANDBOXING`을 `NO`로 설정하세요.

### 수동 설치 (XCFramework)

1. [다운로드](https://sdk.saucelink.im/iOS/SauceLinkSDK-1.0.0.zip)
2. 압축 해제
3. `SauceLinkSDK.xcframework`를 Xcode 프로젝트로 드래그
4. Target > General > Frameworks, Libraries, and Embedded Content에서 "Embed & Sign" 선택

---

## SDK 초기화

Application 시작 시 SDK를 초기화합니다.

### SauceLink.shared.configure

| Parameter | Required | Type | Description |
|:----------|:---------|:-----|:------------|
| **partnerUniqueId** | True | `String` | Sauce로부터 발급받은 파트너 고유 ID |
| **sdkToken** | True | `String` | Sauce로부터 발급받은 파트너 SDK 토큰 |
| **environment** | False | `Environment` | API 환경 설정 (.stage, .prod), 기본값: .prod |
| **completion** | False | `Result<Void, Error> -> Void` | 초기화 결과 Callback |

```swift
import SauceLinkSDK

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // Callback 미사용
        SauceLink.shared.configure(
            partnerUniqueId: "발급받은 파트너ID",
            sdkToken: "sla_발급받은_SDK토큰"
        )

        // Callback 사용
        SauceLink.shared.configure(
            partnerUniqueId: "발급받은 파트너ID",
            sdkToken: "sla_발급받은_SDK토큰",
            environment: .prod
        ) { result in
            switch result {
            case .success:
                print("SDK 초기화 성공")
            case .failure(let error):
                print("SDK 초기화 실패: \(error.localizedDescription)")
            }
        }

        return true
    }
}
```

### SwiftUI

```swift
import SwiftUI
import SauceLinkSDK

@main
struct MyApp: App {
    init() {
        SauceLink.shared.configure(
            partnerUniqueId: "발급받은 파트너ID",
            sdkToken: "sla_발급받은_SDK토큰"
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

---

## 소스링크 트래킹 링크 업데이트

앱스킴으로 앱 진입 시 트래킹 링크값을 SDK에 업데이트해야 합니다.

### SauceLink.shared.updateSlink

| Parameter | Required | Type | Description |
|:----------|:---------|:-----|:------------|
| **slink** | True | `String?` | 앱스킴을 통해 전달된 slink 값 |
| **slinkT** | False | `String?` | sLink 만료 시간 (Unix Timestamp). nil일 경우 7일 후 자동 만료 |

### AppDelegate

```swift
import SauceLinkSDK

func application(_ app: UIApplication,
                 open url: URL,
                 options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {

    let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
    let slink = components?.queryItems?.first(where: { $0.name == "slink" })?.value
    let slinkT = components?.queryItems?.first(where: { $0.name == "sLinkT" })?.value

    SauceLink.shared.updateSlink(slink, slinkT)

    return true
}
```

### SceneDelegate

```swift
import SauceLinkSDK

func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    guard let url = URLContexts.first?.url else { return }

    let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
    let slink = components?.queryItems?.first(where: { $0.name == "slink" })?.value
    let slinkT = components?.queryItems?.first(where: { $0.name == "sLinkT" })?.value

    SauceLink.shared.updateSlink(slink, slinkT)
}
```

### SwiftUI

```swift
import SauceLinkSDK

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
                    let slink = components?.queryItems?.first(where: { $0.name == "slink" })?.value
                    let slinkT = components?.queryItems?.first(where: { $0.name == "sLinkT" })?.value

                    SauceLink.shared.updateSlink(slink, slinkT)
                }
        }
    }
}
```

---

## 이벤트 트래킹

### ProductDetailInfo (상품 상세용)

| Parameter | Required | Type | Description |
|:----------|:---------|:-----|:------------|
| **product_id** | True | `String` | 상품코드 |
| **product_name** | True | `String` | 상품명 |
| **price** | True | `String` | 상품 가격 |
| **discount_price** | True | `String` | 상품 할인 가격 |

### OrderProductInfo (주문용)

| Parameter | Required | Type | Description |
|:----------|:---------|:-----|:------------|
| **product_id** | True | `String` | 상품코드 |
| **product_name** | True | `String` | 상품명 |
| **price** | True | `String` | 상품 가격 |
| **discount_price** | True | `String` | 상품 할인 가격 |
| **quantity** | True | `Int` | 상품 수량 |

---

### 상품 상세 페이지 조회

#### SauceLink.shared.trackProductDetail

| Parameter | Required | Type | Description |
|:----------|:---------|:-----|:------------|
| **product** | True | `ProductDetailInfo` | 상품 상세 정보 |
| **callback** | False | `Result<Void, Error> -> Void` | 결과 Callback |

```swift
import SauceLinkSDK

let product = ProductDetailInfo(
    product_id: "prod-12345",
    product_name: "플라스틱 해머",
    price: "10000",
    discount_price: "8500"
)

SauceLink.shared.trackProductDetail(product: product)
```

---

### 주문 완료

#### SauceLink.shared.trackOrderComplete

| Parameter | Required | Type | Description |
|:----------|:---------|:-----|:------------|
| **orderId** | True | `String` | 주문번호 |
| **products** | True | `[OrderProductInfo]` | 주문 상품 정보 리스트 |
| **callback** | False | `Result<Void, Error> -> Void` | 결과 Callback |

```swift
import SauceLinkSDK

let orderId = "order-67890"
let products = [
    OrderProductInfo(
        product_id: "prod-12345",
        product_name: "플라스틱 해머",
        price: "10000",
        discount_price: "8500",
        quantity: 1
    ),
    OrderProductInfo(
        product_id: "prod-67890",
        product_name: "플라스틱 포크",
        price: "5000",
        discount_price: "4500",
        quantity: 2
    )
]

SauceLink.shared.trackOrderComplete(orderId: orderId, products: products)
```

---

### 주문 취소

#### SauceLink.shared.trackOrderCancel

| Parameter | Required | Type | Description |
|:----------|:---------|:-----|:------------|
| **orderId** | True | `String` | 주문번호 |
| **products** | True | `[OrderProductInfo]` | 주문 상품 정보 리스트 |
| **callback** | False | `Result<Void, Error> -> Void` | 결과 Callback |

```swift
import SauceLinkSDK

let orderId = "order-67890"
let products = [
    OrderProductInfo(
        product_id: "prod-12345",
        product_name: "플라스틱 해머",
        price: "10000",
        discount_price: "8500",
        quantity: 1
    )
]

SauceLink.shared.trackOrderCancel(orderId: orderId, products: products)
```

---

## 사용자 정보 설정

### SauceLink.shared.setUserData

| Parameter | Required | Type | Description |
|:----------|:---------|:-----|:------------|
| **userData** | True | `UserData` | 사용자 정보 |

### UserData

| Parameter | Required | Type | Description |
|:----------|:---------|:-----|:------------|
| **userId** | False | `String?` | 사용자 고유 ID |

```swift
import SauceLinkSDK

let userData = UserData(userId: "user-12345")
SauceLink.shared.setUserData(userData)
```

---

## 커스텀 이벤트 전송

### SauceLink.shared.sendEvent

| Parameter | Required | Type | Description |
|:----------|:---------|:-----|:------------|
| **eventName** | True | `String` | 이벤트 이름 |
| **properties** | False | `[String: Any]?` | 이벤트 속성 |
| **completion** | False | `(Bool, Int?) -> Void` | 결과 Callback (성공 여부, HTTP 상태코드) |

```swift
import SauceLinkSDK

SauceLink.shared.sendEvent("button_click", properties: [
    "button_name": "purchase",
    "screen": "product_detail"
]) { success, statusCode in
    if success {
        print("이벤트 전송 성공")
    }
}
```

---

## SDK 상태 확인

### 속성

| Property | Type | Description |
|:---------|:-----|:------------|
| **isInitialized** | `Bool` | SDK 초기화 완료 여부 |
| **isTokenValid** | `Bool` | 토큰 인증 성공 여부 |
| **lastAuthStatusCode** | `Int` | 마지막 인증 HTTP 상태코드 |

### SauceLink.shared.getAuthStatus

```swift
import SauceLinkSDK

let status = SauceLink.shared.getAuthStatus()
print("초기화: \(status.isInitialized)")
print("토큰 유효: \(status.isTokenValid)")
print("상태코드: \(status.statusCode)")
```

---

## 환경 설정

| 환경 | 용도 |
|-----|-----|
| `.stage` | 스테이징 |
| `.prod` | 프로덕션 (기본값) |

---

## Example 앱

SDK 사용 예제를 확인하려면 Example 앱을 실행하세요.

### 실행 방법

```bash
cd Example
pod install
open SauceLinkExample.xcworkspace
```

### 기능

- SDK 초기화 및 인증 테스트
- 상품 상세 / 주문 완료 / 주문 취소 이벤트 전송
- 딥링크 처리 (URL Scheme, Universal Link)
- 웹뷰 / 네이티브 모드 테스트

---

## 라이선스

MIT License

## 문의

기술 지원: [dev@saucelive.net](mailto:dev@saucelive.net)
