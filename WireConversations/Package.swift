// swift-tools-version: 6.0

import PackageDescription

let WireTestingPackage = Target.Dependency.product(name: "WireTestingPackage", package: "WireFoundation")

let package = Package(
    name: "WireConversations",
    defaultLocalization: "en",
    platforms: [.iOS(.v16), .macOS(.v12)],
    products: [
        .library(name: "WireConversationsAPI", targets: ["WireConversationsAPI"]),
        .library(name: "WireConversationsBindings", targets: ["WireConversationsBindings"]),
        .library(name: "WireConversationsUI", targets: ["WireConversationsUI"]),
        .library(name: "WireConversationsUIBindings", targets: ["WireConversationsUIBindings"]),
    ],
    dependencies: [
        .package(name: "WireFoundation", path: "../WireFoundation"),
        .package(path: "../WirePlugins"),
        .package(name: "WireUI", path: "../WireUI"),
        .package(url: "https://github.com/uber/needle.git", .upToNextMinor(from: "0.25.1"))
    ],
    targets: [
        .target(
            name: "WireConversationsAPI"
        ),
        .target(
            name: "WireConversationsBindings",
            dependencies: [
                .product(name: "NeedleFoundation", package: "needle"),
                "WireConversationsAPI",
                "WireConversationsImplementation",
                "WireConversationsUI"
            ]
        ),
        .target(
            name: "WireConversationsUIBindings",
            dependencies: [
                .product(name: "NeedleFoundation", package: "needle"),
                "WireConversationsAPI",
                "WireConversationsImplementation",
                "WireConversationsUI"
            ]
        ),
        .target(
            name: "WireConversationsImplementation",
            dependencies: [
                "WireConversationsAPI",
                "WireConversationsResources"
            ]
        ),
        .target(
            name: "WireConversationsResources"
        ),
        .target(
            name: "WireConversationsUI",
            dependencies: [
                "WireConversationsAPI",
                "WireConversationsResources",
                "WireConversationsImplementation",
                "WireConversationsImplementationSupport",
                .product(name: "WireDesign", package: "WireUI"),
                .product(name: "WireReusableUIComponents", package: "WireUI"),
                .product(name: "WireFoundation", package: "WireFoundation")
            ],
            plugins: [.plugin(name: "SwiftGenPlugin", package: "WirePlugins")]
        ),
        .target(
            name: "WireConversationsImplementationSupport",
            dependencies: [
                "WireConversationsImplementation",
                "WireConversationsAPI"
            ],
            plugins: [.plugin(name: "SourceryPlugin", package: "WirePlugins")]
        ),
        .testTarget(
            name: "WireConversationsUITests",
            dependencies: [
                "WireConversationsUIBindings",
                "WireConversationsUI",
                "WireConversationsImplementationSupport",
                .product(name: "WireFoundation", package: "WireFoundation")
            ]
        ),
    ]
)

for target in package.targets {
    if target.isTest {
        target.dependencies += [WireTestingPackage]
    }
}

for target in package.targets {
    target.swiftSettings = (target.swiftSettings ?? []) + [
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("ExistentialAny")
    ]
}
