// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "sosumi",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "sosumi",
            targets: ["SosumiCLI"]
        ),
        .library(
            name: "SosumiDocs",
            targets: ["SosumiDocs"]
        ),
        .library(
            name: "SosumiWWDC",
            targets: ["SosumiWWDC"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-testing.git", .upToNextMinor(from: "0.9.0")),
        .package(path: "../smith-rag"),
    ],
    targets: [
        .executableTarget(
            name: "SosumiCLI",
            dependencies: [
                "SosumiDocs",
                "SosumiWWDC",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Logging", package: "swift-log"),
            ]
        ),
        .target(
            name: "SosumiDocs",
            dependencies: []
        ),
        .target(
            name: "SosumiWWDC",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
                .product(name: "SmithRAG", package: "smith-rag"),
            ]
        ),
        .testTarget(
            name: "SosumiWWDCTests",
            dependencies: [
                "SosumiWWDC",
                .product(name: "Testing", package: "swift-testing"),
            ]
        ),
        .testTarget(
            name: "SosumiCLITests",
            dependencies: [
                "SosumiCLI",
                .product(name: "Testing", package: "swift-testing"),
            ]
        ),
    ]
)
