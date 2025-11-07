// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TaskPaper",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        // Library products for BirchOutline and BirchEditor frameworks
        .library(
            name: "BirchOutline",
            type: .dynamic,
            targets: ["BirchOutline"]
        ),
        .library(
            name: "BirchEditor",
            type: .dynamic,
            targets: ["BirchEditor"]
        ),
    ],
    dependencies: [
        // Sparkle - Automatic update framework
        .package(
            url: "https://github.com/sparkle-project/Sparkle",
            from: "2.6.0"
        ),
        // Paddle - Licensing and payment framework
        .package(
            url: "https://github.com/PaddleHQ/Mac-Framework-V4",
            exact: "4.4.3"
        ),
    ],
    targets: [
        // BirchOutline target - Core outline model and JavaScript bridge
        .target(
            name: "BirchOutline",
            dependencies: [
                .product(name: "Sparkle", package: "Sparkle"),
                .product(name: "Paddle", package: "Mac-Framework-V4"),
            ],
            path: "BirchOutline/"
        ),
        // BirchEditor target - Editor view and view model layer
        .target(
            name: "BirchEditor",
            dependencies: [
                "BirchOutline",
                .product(name: "Sparkle", package: "Sparkle"),
                .product(name: "Paddle", package: "Mac-Framework-V4"),
            ],
            path: "BirchEditor/"
        ),
    ]
)
