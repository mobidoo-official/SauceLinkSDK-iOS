// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SauceLinkSDK",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "SauceLinkSDK",
            targets: ["SauceLinkSDK"]
        ),
    ],
    dependencies: [],
    targets: [
        // 배포용 바이너리 타겟
        .binaryTarget(
            name: "SauceLinkSDK",
            url: "https://sdk.saucelink.im/iOS/SauceLinkSDK-1.0.0.zip",
            checksum: "34791bacf6fe7b572dd83e894173494ede623b2515dc4a9d7411c401c9bff735"
        ),

        // 로컬 개발용 소스 타겟 (주석 처리)
        // .target(
        //     name: "SauceLinkSDK",
        //     dependencies: [],
        //     path: "Sources/SauceLink"
        // ),
    ]
)
