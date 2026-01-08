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
            checksum: "8393316127c7e95a3721271d798258b380e2e27124617512710210a18157e1cd"
        ),

        // 로컬 개발용 소스 타겟 (주석 처리)
        // .target(
        //     name: "SauceLinkSDK",
        //     dependencies: [],
        //     path: "Sources/SauceLink"
        // ),
    ]
)
