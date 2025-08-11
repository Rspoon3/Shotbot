// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

@preconcurrency import PackageDescription

let package = Package(
    name: "ShotbotCore",
    platforms: [
        .iOS(.v17),
        .visionOS(.v1)
    ],
    products: [
        .library(for: .appFeature),
        .library(for: .createCombinedImageFeature),
        .library(for: .homeFeature),
        .library(for: .mediaManager),
        .library(for: .models),
        .library(for: .persistence),
        .library(for: .purchases),
        .library(for: .sbFoundation),
        .library(for: .settingsFeature),
        .library(for: .widgetFeature),
        .library(for: .referralFeature)
    ],
    dependencies: [
        .collectionConcurrencyKit,
        .alertToast,
        .revenueCat,
        .swiftTools,
        .referralService
    ],
    targets: [
        .appFeature,
        .createCombinedImageFeature,
        .homeFeature,
        .unitTests(for: .homeFeature),
        .mediaManager,
        .models,
        .unitTests(for: .models),
        .persistence,
        .purchases,
        .sbFoundation,
        .settingsFeature,
        .widgetFeature,
        .referralFeature
    ]
)

// MARK: - Products

extension Product {
    
    // MARK: Library
    
    /// Returns a library product for the specified target.
    ///
    /// - Parameters:
    ///   - target: The target.
    ///   - type: The optional type of the library that’s used to determine how
    ///     to link to the library. Omit this parameter so Swift Package Manager
    ///     can choose between static or dynamic linking (recommended). If you
    ///     don’t support both linkage types, use `.static` or `.dynamic` for
    ///     this parameter.
    /// - Returns: A library product for the specified target.
    static func library(
        for target: Target,
        type: Library.LibraryType? = nil
    ) -> Product {
        .library(
            name: target.name,
            type: type,
            targets: [target.name]
        )
    }
}

// MARK: - Targets

extension Target.Dependency {
    // MARK: Target
    
    /// Returns a target dependency.
    ///
    /// - Parameter target: The target.
    /// - Returns: A target dependency.
    static func target(_ target: Target) -> Target.Dependency {
        .target(name: target.name)
    }
}

extension Target {
    
    static let sbFoundation: Target = .target(
        name: "SBFoundation",
        dependencies: [
            .target(.models)
        ]
    )
    
    static let persistence: Target = .target(
        name: "Persistence",
        dependencies: [
            .target(.models),
            .swiftTools
        ]
    )
    
    static let createCombinedImageFeature: Target = .target(
        name: "CreateCombinedImageFeature",
        dependencies: [
            .target(.models)
        ]
    )
    
    static let widgetFeature: Target = .target(
        name: "WidgetFeature",
        dependencies: [
            .collectionConcurrencyKit
        ]
    )
    
    static let referralFeature: Target = .target(
        name: "ReferralFeature",
        dependencies: [
            .referralService
        ]
    )
    
    static let mediaManager: Target = .target(
        name: "MediaManager",
        dependencies: [
            .target(.models),
            .collectionConcurrencyKit
        ]
    )
    
    static let models: Target = .target(
        name: "Models",
        dependencies: [
            .collectionConcurrencyKit,
            .swiftTools
        ],
        resources: [
            .process("Resources"),
        ]
    )
    
    static let purchases: Target = .target(
        name: "Purchases",
        dependencies: [
            .target(.persistence),
            .revenueCat,
            .swiftTools
        ]
    )
    
    static let settingsFeature: Target = .target(
        name: "SettingsFeature",
        dependencies: [
            .target(.models),
            .target(.persistence),
            .target(.purchases),
            .target(.mediaManager),
            .target(.sbFoundation)
        ]
    )
    
    static let appFeature: Target = .target(
        name: "AppFeature",
        dependencies: [
            .target(.homeFeature),
            .target(.settingsFeature)
        ]
    )
    
    static let homeFeature: Target = .target(
        name: "HomeFeature",
        dependencies: [
            .target(.models),
            .target(.persistence),
            .target(.purchases),
            .target(.mediaManager),
            .target(.sbFoundation),
            .target(.widgetFeature),
            .target(.createCombinedImageFeature),
            .alertToast,
            .swiftTools
        ]
    )
    
    // MARK: - Unit Tests

    static func unitTests(
        for target: Target,
        additionalDependencies: [Target.Dependency] = [],
        resources: [Resource] = []
    ) -> Target {
        .testTarget(
            name: "\(target.name)Tests",
            dependencies: [.target(target)] + additionalDependencies,
            resources: resources
        )
    }
}

extension Target.Dependency {
    static let collectionConcurrencyKit: Target.Dependency = .product(
        name: "CollectionConcurrencyKit",
        package: "CollectionConcurrencyKit"
    )
    
    static let alertToast: Target.Dependency = .product(
        name: "AlertToast",
        package: "AlertToast"
    )
    
    static let revenueCat: Target.Dependency = .product(
        name: "RevenueCat",
        package: "purchases-ios"
    )
    
    static let referralService: Target.Dependency = .product(
        name: "ReferralService",
        package: "ReferralService-iOS"
    )
    
    static let swiftTools: Target.Dependency = .product(
        name: "SwiftTools",
        package: "SwiftTools"
    )
}

extension Package.Dependency {
    static let collectionConcurrencyKit: Package.Dependency = .package(
        url: "https://github.com/JohnSundell/CollectionConcurrencyKit.git",
        exact: .init("0.2.0")!
    )
    
    static let alertToast: Package.Dependency = .package(
        url: "https://github.com/nbapps/AlertToast.git",
        branch: "master"
    )
    
    static let revenueCat: Package.Dependency = .package(
        url: "https://github.com/RevenueCat/purchases-ios.git",
        exact: .init("5.2.2")!
    )
    
    static let swiftTools: Package.Dependency = .package(
        url: "https://github.com/Rspoon3/SwiftTools",
        exact: "2.2.4"
    )
    
    static let referralService: Package.Dependency = .package(
        url: "https://github.com/Rspoon3/ReferralService-iOS.git",
        branch: "main"
    )
}
