// swift-tools-version: 6.1

import PackageDescription

let WireTestingPackage = Target.Dependency.product(name: "WireTestingPackage", package: "WireFoundation")

let package = Package(
    name: "WireCalling",
    defaultLocalization: "en",
    platforms: [.iOS("16.4"), .macOS(.v12)],
    products: [
        .library(name: "WireCallingDomain", targets: ["WireCallingDomain"]),
        .library(name: "WireCallingAssembly", targets: ["WireCallingAssembly"]),
        .library(name: "WireCallingUI", targets: ["WireCallingUI"])
    ],
    dependencies: [
        .package(path: "../WireFoundation"),
        .package(path: "../WirePlugins"),
        .package(path: "../WireLogging"),
        .package(name: "WireUI", path: "../WireUI")
    ],
    targets: [
        .target(
            name: "WireCallingDomain",
            dependencies: [
                "WireFoundation",
                "WireLogging",
                .product(name: "WireLegacyLogging", package: "WireLogging")
            ]
        ),
        .target(
            name: "WireCallingDomainSupport",
            dependencies: [
                "WireCallingDomain",
                "WireCallingData"
            ],
            plugins: [.plugin(name: "SourceryPlugin", package: "WirePlugins")]
        ),
        .target(
            name: "WireCallingData",
            dependencies: [
                "WireCallingDomain",
                "WireLogging",
                .product(name: "WireLegacyLogging", package: "WireLogging")
            ]
        ),
        .target(
            name: "WireCallingAssembly",
            dependencies: [
                "WireCallingDomain",
                "WireCallingUI",
                "WireCallingData"
            ]
        ),
        .target(
            name: "WireCallingUI",
            dependencies: [
                "WireCallingDomain",
                "WireCallingDomainSupport",
                .product(name: "WireDesign", package: "WireUI"),
                .product(name: "WireReusableUIComponents", package: "WireUI"),
                "WireFoundation"
            ],
            plugins: [.plugin(name: "SwiftGenPlugin", package: "WirePlugins")]
        ),
        .testTarget(
            name: "WireCallingTests",
            dependencies: [
                "WireCallingDomain",
                "WireCallingDomainSupport",
                "WireCallingData",
                .product(name: "WireFoundationSupport", package: "WireFoundation")
            ],
        ),
        .testTarget(
            name: "WireCallingUITests",
            dependencies: [
                "WireCallingUI",
                "WireCallingDomain",
                "WireCallingDomainSupport",
                .product(name: "WireDesign", package: "WireUI"),
                .product(name: "WireFoundationSupport", package: "WireFoundation")
            ],
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
