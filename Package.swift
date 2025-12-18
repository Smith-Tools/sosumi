// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "sosumi",
    platforms: [
        .macOS(.v15)
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
        .package(path: "../smith-docc-extractor"),
    ],
    targets: [
        .executableTarget(
            name: "SosumiCLI",
            dependencies: [
                "SosumiDocs",
                "SosumiWWDC",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "SmithRAGCommands", package: "smith-rag"),
            ]
        ),
        // SosumiDocs: Documentation Fetching Logic
        .target(
            name: "SosumiDocs",
            dependencies: [
                .product(name: "SmithRAG", package: "smith-rag"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "SmithDoccExtractor", package: "smith-docc-extractor"),
            ]
        ),
        .target(
            name: "SosumiWWDC",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
                .product(name: "SmithRAG", package: "smith-rag"),
            ]
        ),
        .testTarget(
            name: "SosumiDocsTests",
            dependencies: [
                "SosumiDocs",
                .product(name: "Testing", package: "swift-testing"),
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
