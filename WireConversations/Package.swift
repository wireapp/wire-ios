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
            name: "WireConversationsResources",
            plugins: [.plugin(name: "SwiftGenPlugin", package: "WirePlugins")]
        ),
        .target(
            name: "WireConversationsUI",
            dependencies: [
                "WireConversationsAPI",
                "WireConversationsResources"
            ]
        ),
        .testTarget(
            name: "WireConversationsUITests",
            dependencies: ["WireConversationsUIBindings"]
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
