// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ShotbotCore",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "AppFeature", targets: ["AppFeature"]),
        .library(name: "Models", targets: ["Models"]),
        .library(name: "HomeFeature", targets: ["HomeFeature"]),
        .library(name: "Persistence", targets: ["Persistence"]),
        .library(name: "Purchases", targets: ["Purchases"]),
        .library(name: "MediaManager", targets: ["MediaManager"]),
        .library(name: "SettingsFeature", targets: ["SettingsFeature"]),
        .library(name: "SBFoundation", targets: ["SBFoundation"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/JohnSundell/CollectionConcurrencyKit.git",
            exact: .init("0.2.0")!
        ),
        .package(
            url: "https://github.com/GodL/AlertToast.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/RevenueCat/purchases-ios.git",
            exact: .init("4.36.3")!
        )
    ],
    targets: [
        .target(
            name: "AppFeature",
            dependencies: [
                "HomeFeature",
                "SettingsFeature"
            ]
        ),
        .target(
            name: "Models",
            dependencies: [
                .product(name: "CollectionConcurrencyKit", package: "CollectionConcurrencyKit"),
            ],
            resources: [.process("Resources")]
        ),
        .testTarget(name: "ModelsTests", dependencies: ["Models"]),
        .target(
            name: "HomeFeature",
            dependencies: [
                "Models",
                "Persistence",
                "Purchases",
                "MediaManager",
                "SBFoundation",
                .product(name: "AlertToast", package: "AlertToast")
            ]
        ),
        .testTarget(name: "HomeFeatureTests", dependencies: ["HomeFeature"]),
        .target(
            name: "Persistence",
            dependencies: [
                "Models"
            ]
        ),
        .target(
            name: "Purchases",
            dependencies: [
                "Persistence",
                .product(name: "RevenueCat", package: "purchases-ios"),
            ]
        ),
        .target(
            name: "MediaManager",
            dependencies: [
                "Models",
                .product(name: "CollectionConcurrencyKit", package: "CollectionConcurrencyKit"),
            ]
        ),
        .target(
            name: "SettingsFeature",
            dependencies: [
                "Models",
                "Persistence",
                "Purchases",
                "MediaManager",
                "SBFoundation"
            ]
        ),
        .target(
            name: "SBFoundation",
            dependencies: [
                "Models"
            ]
        )
    ]
)
