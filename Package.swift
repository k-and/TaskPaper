// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TaskPaper",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        // BirchOutline library product
        .library(
            name: "BirchOutline",
            targets: ["BirchOutline"]),

        // BirchEditor library product
        .library(
            name: "BirchEditor",
            targets: ["BirchEditor"]),
    ],
    dependencies: [
        // Sparkle Framework for automatic updates
        // Note: Upgrading from Sparkle 1.27.3 (Carthage) to 2.6.0+ (SPM)
        // Breaking changes: Sparkle 2.x has different API from 1.x
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.6.0"),

        // Paddle Framework for licensing
        // Note: PaddleHQ v4.4.3 does not support SPM
        // Manual integration required - see docs/modernisation/paddle-integration.md
    ],
    targets: [
        // BirchOutline Swift wrapper around birch-outline.js model layer
        .target(
            name: "BirchOutline",
            dependencies: [],
            path: "BirchOutline/BirchOutline.swift",
            exclude: [
                "BirchOutline.xcodeproj",
                "BirchOutlineTests"
            ],
            sources: ["Common/Sources"],
            resources: [
                // Include JavaScript bundle from birch-outline.js
                .copy("Resources")
            ]
        ),

        // BirchEditor Swift wrapper around birch-editor.js view model layer
        .target(
            name: "BirchEditor",
            dependencies: [
                "BirchOutline",
                .product(name: "Sparkle", package: "Sparkle")
            ],
            path: "BirchEditor/BirchEditor.swift",
            exclude: [
                "BirchEditor.xcodeproj",
                "BirchEditorTests"
            ],
            sources: ["BirchEditor"],
            resources: [
                // Include JavaScript bundle from birch-editor.js
                .copy("Resources")
            ]
        ),

        // TaskPaper main application
        // Note: This is typically not included in Package.swift for app projects
        // Kept here for completeness, but app targets are managed by Xcode project

        // Test targets
        .testTarget(
            name: "BirchOutlineTests",
            dependencies: ["BirchOutline"],
            path: "BirchOutline/BirchOutline.swift/BirchOutlineTests"
        ),

        .testTarget(
            name: "BirchEditorTests",
            dependencies: ["BirchEditor"],
            path: "BirchEditor/BirchEditor.swift/BirchEditorTests"
        ),
    ]
)
