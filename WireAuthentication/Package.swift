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
        .library(name: "WireAuthenticationDomain", targets: ["WireAuthenticationDomain"]),
        .library(name: "WireAuthenticationData", targets: ["WireAuthenticationData"]),
        .library(name: "WireAuthenticationUI", targets: ["WireAuthenticationUI"])
    ],
    dependencies: [
        .package(path: "../WireAPI"),
        .package(path: "../WireFoundation"),
        .package(path: "../WireLogging"),
        .package(path: "../WireUI"),
        .package(path: "../WirePlugins"),
        .package(url: "https://github.com/uber/needle.git", .upToNextMinor(from: "0.25.1")),
        .package(url: "https://github.com/siteline/swiftui-introspect", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "WireAuthentication",
            dependencies: [
                "WireAuthenticationDomain",
                "WireAuthenticationUI",
                "WireAuthenticationData",
                "WireFoundation",
                .product(name: "NeedleFoundation", package: "needle")
            ]
        ),
        .testTarget(
            name: "WireAuthenticationTests",
            dependencies: ["WireAuthentication"]
        ),

        .target(
            name: "WireAuthenticationDomain",
            dependencies: ["WireAPI"] // TODO: NOT needed here
        ),
        .target(
            name: "WireAuthenticationDomainSupport",
            dependencies: ["WireAuthenticationDomain"],
            plugins: [
                .plugin(name: "SourceryPlugin", package: "WirePlugins")
            ]
        ),

        .target(
            name: "WireAuthenticationData",
            dependencies: ["WireAuthenticationDomain", "WireAPI", "WireFoundation"]
        ),
        .testTarget(
            name: "WireAuthenticationLogicTests",
            dependencies: [
                "WireAuthenticationData",
                "WireAuthenticationDomainSupport",
                .product(name: "WireAPISupport", package: "WireAPI"),
            ]
        ),

        .target(
            name: "WireAuthenticationUI",
            dependencies: [
                "WireAuthenticationDomain",
                .product(name: "WireDesign", package: "WireUI"),
                .product(name: "WireReusableUIComponents", package: "WireUI"),
                "WireLogging",
                .product(name: "SwiftUIIntrospect", package: "swiftui-introspect")
            ],
            plugins: [.plugin(name: "SwiftGenPlugin", package: "WirePlugins")]
        ),
        .testTarget(
            name: "WireAuthenticationUITests",
            dependencies: [
                "WireAuthenticationUI",
                "WireAuthenticationDomainSupport",
                "WireFoundation",
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
