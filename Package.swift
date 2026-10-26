// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "MobileCI",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .library(name: "MobileCIKit", targets: ["MobileCIKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/jpsim/Yams.git", from: "6.2.2")
    ],
    targets: [
        .target(
            name: "MobileCIKit",
            dependencies: [
                .product(name: "Yams", package: "Yams")
            ]
        ),
        .testTarget(
            name: "MobileCIKitTests",
            dependencies: ["MobileCIKit"]
        )
    ]
)
