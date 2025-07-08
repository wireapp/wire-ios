// swift-tools-version: 6.0

import PackageDescription

let WireTestingPackage = Target.Dependency.product(name: "WireTestingPackage", package: "WireFoundation")

let package = Package(
    name: "WireMessaging",
    defaultLocalization: "en",
    platforms: [.iOS("16.4"), .macOS(.v12)],
    products: [
        .library(name: "WireMessagingAPI", targets: ["WireMessagingAPI"]),
        .library(name: "WireMessagingBindings", targets: ["WireMessagingBindings"]),
        .library(name: "WireMessagingUI", targets: ["WireMessagingUI"]),
        .library(name: "WireMessagingUIBindings", targets: ["WireMessagingUIBindings"])
    ],
    dependencies: [
        .package(name: "WireFoundation", path: "../WireFoundation"),
        .package(path: "../WirePlugins"),
        .package(name: "WireUI", path: "../WireUI")
    ],
    targets: [
        .target(
            name: "WireMessagingAPI"
        ),
        .target(
            name: "WireMessagingBindings",
            dependencies: [
                "WireMessagingAPI",
                "WireMessagingImplementation"
            ]
        ),
        .target(
            name: "WireMessagingUIBindings",
            dependencies: [
                "WireMessagingAPI",
                "WireMessagingImplementation",
                "WireMessagingUI"
            ]
        ),
        .target(
            name: "WireMessagingImplementation",
            dependencies: [
                "WireMessagingAPI",
                "WireMessagingResources",
                "WireFoundation"
            ]
        ),
        .target(
            name: "WireMessagingResources"
        ),
        .target(
            name: "WireMessagingUI",
            dependencies: [
                "WireMessagingAPI",
                "WireMessagingImplementation",
                "WireMessagingImplementationSupport",
                "WireMessagingResources",
                .product(name: "WireDesign", package: "WireUI"),
                .product(name: "WireReusableUIComponents", package: "WireUI"),
                "WireFoundation"
            ],
            plugins: [.plugin(name: "SwiftGenPlugin", package: "WirePlugins")]
        ),
        .target(
            name: "WireMessagingImplementationSupport",
            dependencies: [
                "WireMessagingImplementation",
                "WireMessagingAPI"
            ],
            plugins: [.plugin(name: "SourceryPlugin", package: "WirePlugins")]
        ),
        .testTarget(
            name: "WireMessagingTests",
            dependencies: [
                "WireMessagingUI",
                "WireFoundation"
            ]
        ),
        .testTarget(
            name: "WireMessagingUITests",
            dependencies: [
                "WireMessagingUIBindings",
                "WireMessagingUI",
                "WireMessagingImplementationSupport",
                .product(name: "WireDesign", package: "WireUI"),
                "WireFoundation"
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
