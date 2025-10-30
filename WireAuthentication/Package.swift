// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let WireTestingPackage = Target.Dependency.product(name: "WireTestingPackage", package: "WireFoundation")

let package = Package(
    name: "WireAuthentication",
    defaultLocalization: "en",
    platforms: [.iOS("16.4"), .macOS(.v12)],
    products: [
        .library(name: "WireAuthentication", targets: ["WireAuthentication"]),
        .library(name: "WireAuthenticationAPI", targets: ["WireAuthenticationAPI"]),
        .library(name: "WireAuthenticationLogic", targets: ["WireAuthenticationLogic"]),
        .library(name: "WireAuthenticationUI", targets: ["WireAuthenticationUI"])
    ],
    dependencies: [
        .package(path: "../WireNetwork"),
        .package(path: "../WireFoundation"),
        .package(path: "../WireLogging"),
        .package(path: "../WireUI"),
        .package(path: "../WirePlugins"),
        .package(url: "https://github.com/uber/needle.git", .upToNextMinor(from: "0.25.1")),
        .package(url: "https://github.com/siteline/swiftui-introspect", from: "26.0.0"),
    ],
    targets: [
        .target(
            name: "WireAuthentication",
            dependencies: [
                "WireAuthenticationAPI",
                "WireAuthenticationUI",
                "WireAuthenticationLogic",
                "WireFoundation",
                .product(name: "NeedleFoundation", package: "needle")
            ]
        ),

        .target(
            name: "WireAuthenticationAPI",
            dependencies: ["WireNetwork"]
        ),
        .target(
            name: "WireAuthenticationAPISupport",
            dependencies: ["WireAuthenticationAPI", "WireNetwork"],
            plugins: [
                .plugin(name: "SourceryPlugin", package: "WirePlugins")
            ]
        ),

        .target(
            name: "WireAuthenticationLogic",
            dependencies: ["WireAuthenticationAPI", "WireNetwork", "WireFoundation"]
        ),
        .testTarget(
            name: "WireAuthenticationLogicTests",
            dependencies: [
                "WireAuthenticationLogic",
                "WireAuthenticationAPISupport",
                .product(name: "WireNetworkSupport", package: "WireNetwork"),
            ]
        ),

        .target(
            name: "WireAuthenticationUI",
            dependencies: [
                "WireLogging",
                "WireFoundation",
                "WireAuthenticationAPI",
                .product(name: "WireDesign", package: "WireUI"),
                .product(name: "WireMultiBackendUI", package: "WireUI"),
                .product(name: "WireReusableUIComponents", package: "WireUI"),
                .product(name: "SwiftUIIntrospect", package: "swiftui-introspect")
            ],
            plugins: [.plugin(name: "SwiftGenPlugin", package: "WirePlugins")]
        ),
        .testTarget(
            name: "WireAuthenticationUITests",
            dependencies: [
                "WireAuthenticationUI",
                "WireAuthenticationAPISupport",
                "WireFoundation",
                "WireNetwork",
                .product(name: "WireReusableUIComponentsSupport", package: "WireUI"),
            ]
        )
    ]
)

for target in package.targets {
    if target.isTest {
        target.dependencies += [WireTestingPackage]
    }
    target.swiftSettings = (target.swiftSettings ?? []) + [
        // TODO: [WPB-15967] Enable `ExistentialAny` upcoming feature
        .enableUpcomingFeature("GlobalConcurrency"),
        .enableExperimentalFeature("StrictConcurrency"),
        .unsafeFlags(["-enable-bare-slash-regex"]) // For regex literals
    ]
}
