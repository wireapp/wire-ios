// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let WireTestingPackage = Target.Dependency.product(name: "WireTestingPackage", package: "WireFoundation")
let SnapshotTestReferenceDirectoryPlugin = Target.PluginUsage.plugin(name: "SnapshotTestReferenceDirectoryPlugin", package: "WireFoundation")

let package = Package(
    name: "WireUI",
    defaultLocalization: "en",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library(name: "WireAccountImage", targets: ["WireAccountImage"]),
        .library(name: "WireConversationListNavigation", targets: ["WireConversationListNavigation"]),
        .library(name: "WireDesign", targets: ["WireDesign"]),
        .library(name: "WireMainNavigation", targets: ["WireMainNavigation"]),
        .library(name: "WireReusableUIComponents", targets: ["WireReusableUIComponents"]),
        .library(name: "WireSettings", targets: ["WireSettings"]),
        .library(name: "WireSidebar", targets: ["WireSidebar"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.1.0"),
        .package(name: "WireFoundation", path: "../WireFoundation")
    ],
    targets: [
        .target(name: "WireAccountImage", dependencies: ["WireFoundation"]),
        .testTarget(name: "WireAccountImageTests", dependencies: ["WireAccountImage", "WireFoundation"]),

        .target(name: "WireConversationListNavigation"), // TODO: rename `WireConversationList`
        .testTarget(name: "WireConversationListNavigationTests", dependencies: ["WireConversationListNavigation"]),

        .target(name: "WireDesign", dependencies: ["WireFoundation"]),
        .testTarget(name: "WireDesignTests", dependencies: ["WireDesign"]),

        .target(name: "WireMainNavigation"),
        .testTarget(name: "WireMainNavigationTests", dependencies: ["WireMainNavigation"]),

        .target(name: "WireReusableUIComponents", dependencies: ["WireDesign", "WireFoundation"]),
        .testTarget(name: "WireReusableUIComponentsTests", dependencies: ["WireReusableUIComponents"]),

        .target(name: "WireSettings"),
        .testTarget(name: "WireSettingsTests", dependencies: ["WireSettings"]),

        .target(name: "WireSidebar", dependencies: ["WireFoundation"]),
        .testTarget(name: "WireSidebarTests", dependencies: ["WireSidebar"])
    ]
)

for target in package.targets {
    target.plugins = (target.plugins ?? []) + [SnapshotTestReferenceDirectoryPlugin]
    if target.isTest {
        target.dependencies += [WireTestingPackage]
    }
    target.swiftSettings = (target.swiftSettings ?? []) + [
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("GlobalConcurrency"),
        .enableExperimentalFeature("StrictConcurrency")
    ]
}
