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
        .binaryTarget(
            name: "SauceLinkSDK",
            url: "https://sdk.saucelink.im/iOS/SauceLinkSDK-1.0.0.zip",
            checksum: "1e881712638878786a02fad50d8d44f0a4fc7f8de37e443d9b78e29068255aff"
        ),
    ]
)
