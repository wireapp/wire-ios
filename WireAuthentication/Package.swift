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
        .library(name: "WireAuthenticationAPI", targets: ["WireAuthenticationAPI"]),
        .library(name: "WireAuthenticationLogic", targets: ["WireAuthenticationLogic"]),
        .library(name: "WireAuthenticationUI", targets: ["WireAuthenticationUI"])
    ],
    dependencies: [
        .package(name: "WireAPI", path: "../WireAPI"),
        .package(name: "WireFoundation", path: "../WireFoundation"),
        .package(path: "../WireLogging"),
        .package(name: "WireUI", path: "../WireUI"),
        .package(path: "../WirePlugins"),
        .package(url: "https://github.com/uber/needle.git", .upToNextMinor(from: "0.25.1")),
    ],
    targets: [
        .target(
            name: "WireAuthentication",
            dependencies: [
                "WireAuthenticationAPI",
                "WireAuthenticationUI",
                "WireAuthenticationLogic",
                .product(name: "NeedleFoundation", package: "needle")
            ]
        ),
        .testTarget(
            name: "WireAuthenticationTests",
            dependencies: ["WireAuthentication"]
        ),

        .target(
            name: "WireAuthenticationAPI"
        ),
        .target(
            name: "WireAuthenticationAPISupport",
            dependencies: ["WireAuthenticationAPI"]
        ),

        .target(
            name: "WireAuthenticationLogic",
            dependencies: ["WireAuthenticationAPI", "WireAPI"]
        ),
        .testTarget(
            name: "WireAuthenticationLogicTests",
            dependencies: [
                "WireAuthenticationLogic",
                .product(name: "WireAPISupport", package: "WireAPI"),
            ]
        ),

        .target(
            name: "WireAuthenticationUI",
            dependencies: [
                "WireAuthenticationAPI",
                .product(name: "WireDesign", package: "WireUI"),
                "WireFoundation",
                .product(name: "WireReusableUIComponents", package: "WireUI"),
                "WireLogging"
            ],
            plugins: [.plugin(name: "SwiftGenPlugin", package: "WirePlugins")]
        ),
        .testTarget(
            name: "WireAuthenticationUITests",
            dependencies: ["WireAuthenticationUI"]
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
