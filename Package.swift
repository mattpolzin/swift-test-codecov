// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-test-codecov",
    products: [
        .executable(name: "swift-test-codecov", targets: ["swift-test-codecov"]),
        .library(name: "SwiftTestCodecovLib", targets: ["SwiftTestCodecovLib"]),
        .library(name: "SwiftTestCodecovLogic", targets: ["SwiftTestCodecovLogic"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", .upToNextMinor(from: "0.3.1")),
        .package(url: "https://github.com/mattpolzin/TextTable.git", .branch("swift-5")),
        .package(url: "https://github.com/sharplet/Regex.git", .upToNextMinor(from: "2.1.0"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "swift-test-codecov",
            dependencies: ["SwiftTestCodecovLib", "SwiftTestCodecovLogic", "ArgumentParser", "TextTable"]
        ),
        // Executable targets are not unit testable so this target is necessary to unit test the executable's logic
        .target(
            name: "SwiftTestCodecovLogic",
            dependencies: ["SwiftTestCodecovLib", "TextTable"]
        ),
        .testTarget(
            name: "SwiftTestCodecovLogicTests",
            dependencies: ["SwiftTestCodecovLogic", "SwiftTestCodecovLib"]
        ),
        .target(
            name: "SwiftTestCodecovLib",
            dependencies: ["Regex"]
        ),
        .testTarget(
            name: "SwiftTestCodecovLibTests",
            dependencies: ["SwiftTestCodecovLib", "Regex"]
        ),
    ]
)
