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
            checksum: "5f7c24f891b375f25021d9a4c51905851c85287237b61ac694c6b7381ee34bd1"
        ),

        // 로컬 개발용 소스 타겟 (주석 처리)
        // .target(
        //     name: "SauceLinkSDK",
        //     dependencies: [],
        //     path: "Sources/SauceLink"
        // ),
    ]
)
