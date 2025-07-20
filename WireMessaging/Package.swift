// swift-tools-version: 6.0

import PackageDescription

let WireTestingPackage = Target.Dependency.product(name: "WireTestingPackage", package: "WireFoundation")

let package = Package(
    name: "WireMessaging",
    defaultLocalization: "en",
    platforms: [.iOS("16.4"), .macOS(.v12)],
    products: [
        .library(name: "WireMessagingDomain", targets: ["WireMessagingDomain"]),
        .library(name: "WireMessagingAssembly", targets: ["WireMessagingAssembly"]),
        .library(name: "WireMessagingUI", targets: ["WireMessagingUI"])
    ],
    dependencies: [
        .package(name: "WireFoundation", path: "../WireFoundation"),
        .package(path: "../WirePlugins"),
        .package(name: "WireUI", path: "../WireUI")
    ],
    targets: [
        .target(
            name: "WireMessagingDomain",
            dependencies: [
                "WireMessagingResources",
                "WireFoundation"
            ]
        ),
        .target(
            name: "WireMessagingAssembly",
            dependencies: [
                "WireMessagingDomain",
                "WireMessagingUI"
            ]
        ),
        .target(
            name: "WireMessagingResources"
        ),
        .target(
            name: "WireMessagingUI",
            dependencies: [
                "WireMessagingDomain",
                "WireMessagingDomainSupport",
                "WireMessagingResources",
                .product(name: "WireDesign", package: "WireUI"),
                .product(name: "WireReusableUIComponents", package: "WireUI"),
                .product(name: "WireAccountImageUI", package: "WireUI"),
                "WireFoundation"
            ],
            plugins: [.plugin(name: "SwiftGenPlugin", package: "WirePlugins")]
        ),
        .target(
            name: "WireMessagingDomainSupport",
            dependencies: [
                "WireMessagingDomain"
            ],
            plugins: [.plugin(name: "SourceryPlugin", package: "WirePlugins")]
        ),
        .testTarget(
            name: "WireMessagingUITests",
            dependencies: [
                "WireMessagingAssembly",
                "WireMessagingUI",
                "WireMessagingDomainSupport",
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
