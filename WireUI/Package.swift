// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let WireTestingPackage = Target.Dependency.product(name: "WireTestingPackage", package: "WireFoundation")

let package = Package(
    name: "WireUI",
    defaultLocalization: "en",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library(name: "WireAccountImageUI", targets: ["WireAccountImageUI"]),
        .library(name: "WireConversationListUI", targets: ["WireConversationListUI"]),
        .library(name: "WireDesign", targets: ["WireDesign"]),
        .library(name: "WireMainNavigationUI", targets: ["WireMainNavigationUI"]),
        .library(name: "WireReusableUIComponents", targets: ["WireReusableUIComponents"]),
        .library(name: "WireSettingsUI", targets: ["WireSettingsUI"]),
        .library(name: "WireSidebarUI", targets: ["WireSidebarUI"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.1.0"),
        .package(name: "WireFoundation", path: "../WireFoundation")
    ],
    targets: [
        .target(name: "WireAccountImageUI", dependencies: ["WireFoundation"]),
        .testTarget(name: "WireAccountImageUITests", dependencies: ["WireAccountImageUI", "WireFoundation"]),

        .target(name: "WireConversationListUI"),
        .testTarget(name: "WireConversationListUITests", dependencies: ["WireConversationListUI"]),

        .target(name: "WireDesign", dependencies: ["WireFoundation"]),
        .testTarget(name: "WireDesignTests", dependencies: ["WireDesign"]),

        .target(name: "WireMainNavigationUI"),
        .testTarget(name: "WireMainNavigationUITests", dependencies: ["WireMainNavigationUI"]),

        .target(name: "WireReusableUIComponents", dependencies: ["WireDesign", "WireFoundation"]),
        .testTarget(name: "WireReusableUIComponentsTests", dependencies: ["WireReusableUIComponents"]),

        .target(name: "WireSettingsUI"),
        .testTarget(name: "WireSettingsUITests", dependencies: ["WireSettingsUI"]),

        .target(name: "WireSidebarUI", dependencies: ["WireFoundation"]),
        .testTarget(name: "WireSidebarUITests", dependencies: ["WireSidebarUI"])
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
