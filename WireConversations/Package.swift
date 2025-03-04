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
    ],
    dependencies: [
        .package(path: "../WireFoundation"),
        .package(path: "../WirePlugins")
    ],
    targets: [
        .target(
            name: "WireConversationsAPI"
        ),
        .target(
            name: "WireConversationsBindings"
        ),
        .target(
            name: "WireConversationsImplementation"
        ),
        .target(
            name: "WireConversationsUI",
            plugins: [.plugin(name: "SwiftGenPlugin", package: "WirePlugins")]
        ),
        .testTarget(
            name: "WireConversationsUITests",
            dependencies: ["WireConversationsUI"]
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
