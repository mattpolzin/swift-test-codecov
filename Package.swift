// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-test-codecov",
    products: [
        .executable(name: "swift-test-codecov", targets: ["swift-test-codecov"]),
        .library(name: "SwiftTestCodecovLib", targets: ["SwiftTestCodecovLib"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", .upToNextMinor(from: "0.3.1"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "swift-test-codecov",
            dependencies: ["SwiftTestCodecovLib", "ArgumentParser"]
        ),
        .testTarget(
            name: "swift-test-codecovTests",
            dependencies: ["swift-test-codecov"]
        ),
        .target(
            name: "SwiftTestCodecovLib",
            dependencies: []
        ),
        .testTarget(
            name: "SwiftTestCodecovLibTests",
            dependencies: ["SwiftTestCodecovLib"]
        ),
    ]
)
