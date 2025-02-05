// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let WireTestingPackage = Target.Dependency.product(name: "WireTestingPackage", package: "WireFoundation")

let package = Package(
    name: "WireAuthentication",
    defaultLocalization: "en",
    platforms: [.iOS(.v16), .macOS(.v12)],
    products: [
        .library(name: "WireAuthentication", targets: ["WireAuthentication"]),
        .library(name: "WireAuthenticationUI", targets: ["WireAuthenticationUI"]),
        .library(name: "WireViewsDebugUI", targets: ["WireViewsDebugUI"])
    ],
    dependencies: [
        .package(name: "WireDomainPackage", path: "../WireDomain"),
        .package(name: "WireFoundation", path: "../WireFoundation"),
        .package(name: "WireUI", path: "../WireUI"),
        .package(path: "../WirePlugins"),
    ],
    targets: [
        .target(
            name: "WireAuthentication"
        ),
        .testTarget(
            name: "WireAuthenticationTests",
            dependencies: ["WireAuthentication"]
        ),

        .target(
            name: "WireAuthenticationUI",
            dependencies: [
                .product(name: "WireDesign", package: "WireUI"),
                "WireFoundation",
                .product(name: "WireReusableUIComponents", package: "WireUI"),
            ],
            plugins: [.plugin(name: "SwiftGenPlugin", package: "WirePlugins")]
        ),
        .testTarget(
            name: "WireAuthenticationUITests",
            dependencies: ["WireAuthenticationUI"]
        ),

        .target(
            name: "WireViewsDebugUI",
            dependencies: [
                "WireAuthenticationUI",
                .product(name: "WireDomainPackage", package: "WireDomainPackage"),
                "WireFoundation",
                .product(name: "WireReusableUIComponents", package: "WireUI"),
            ]
        )
    ]
)

for target in package.targets {
    if target.isTest {
        target.dependencies += [WireTestingPackage]
    }
    target.swiftSettings = (target.swiftSettings ?? []) + [
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("GlobalConcurrency"),
        .enableExperimentalFeature("StrictConcurrency")
    ]
}
