// swift-tools-version: 6.0
//
// Package.swift — Swift Package Manager manifest for NvidiaLLM.
//
// Note: This project is primarily designed to be built with Xcode.
// This Package.swift allows SPM-based tooling and CI to resolve dependencies.
// The actual app target requires Xcode for SwiftUI/SwiftData macOS app building.

import PackageDescription

let package = Package(
    name: "NvidiaLLM",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(
            name: "NvidiaLLM",
            targets: ["NvidiaLLM"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/gonzalezreal/swift-markdown-ui", from: "2.4.0"),
        .package(url: "https://github.com/soffes/HotKey", from: "0.2.0")
    ],
    targets: [
        .executableTarget(
            name: "NvidiaLLM",
            dependencies: [
                .product(name: "MarkdownUI", package: "swift-markdown-ui"),
                .product(name: "HotKey", package: "HotKey")
            ],
            path: ".",
            exclude: [
                "Tests",
                "Resources",
                "README.md",
                ".gitignore"
            ]
        ),
        .testTarget(
            name: "NvidiaLLMTests",
            dependencies: ["NvidiaLLM"],
            path: "Tests"
        )
    ]
)
