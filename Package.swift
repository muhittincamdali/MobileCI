// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MobileCI",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "mobileci",
            targets: ["MobileCI"]
        ),
        .library(
            name: "MobileCIKit",
            targets: ["MobileCIKit"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.0"),
        .package(url: "https://github.com/onevcat/Rainbow.git", from: "4.0.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.0"),
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.19.0"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", from: "1.8.0")
    ],
    targets: [
        .executableTarget(
            name: "MobileCI",
            dependencies: [
                "MobileCIKit",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .target(
            name: "MobileCIKit",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Yams", package: "Yams"),
                .product(name: "Rainbow", package: "Rainbow"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
                .product(name: "CryptoSwift", package: "CryptoSwift")
            ]
        ),
        .testTarget(
            name: "MobileCITests",
            dependencies: ["MobileCIKit"]
        )
    ]
)
