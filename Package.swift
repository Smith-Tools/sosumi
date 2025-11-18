// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "sosumi",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "sosumi",
            targets: ["SosumiCLI"]
        ),
        .library(
            name: "SosumiCore",
            targets: ["SosumiCore"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "SosumiCLI",
            dependencies: [
                "SosumiCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Logging", package: "swift-log"),
            ],
            path: "Sources/SosumiCLI",
            swiftSettings: [
                .unsafeFlags(["-Xfrontend", "-disable-availability-checking", "-Xfrontend", "-strict-concurrency=off"])
            ]
        ),
        .target(
            name: "SosumiCore",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
            ],
            path: "Sources/SosumiCore",
            swiftSettings: [
                .unsafeFlags(["-Xfrontend", "-disable-availability-checking", "-Xfrontend", "-strict-concurrency=off"])
            ]
        ),
    ]
)