// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "MobileCI",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .executable(name: "mobileci", targets: ["mobileci"]),
        .library(name: "MobileCIKit", targets: ["MobileCIKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.8.2"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "6.2.2")
    ],
    targets: [
        .target(
            name: "MobileCIKit",
            dependencies: [
                .product(name: "Yams", package: "Yams")
            ]
        ),
        .executableTarget(
            name: "mobileci",
            dependencies: [
                "MobileCIKit",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .testTarget(
            name: "MobileCIKitTests",
            dependencies: ["MobileCIKit"]
        )
    ]
)
