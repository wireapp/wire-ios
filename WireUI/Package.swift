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
        .library(name: "WireDesign", targets: ["WireDesign"]),
        .library(name: "WireReusableUIComponents", targets: ["WireReusableUIComponents"]),
        .library(name: "WireSidebar", targets: ["WireSidebar"]),
        .library(name: "WireMainNavigation", targets: ["WireMainNavigation"]),
        .library(name: "WireConversationListNavigation", targets: ["WireConversationListNavigation"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.1.0"),
        .package(name: "WireFoundation", path: "../WireFoundation")
    ],
    targets: [
        .target(name: "WireDesign", dependencies: ["WireFoundation"]),
        .testTarget(name: "WireDesignTests", dependencies: ["WireDesign"]),

        .target(name: "WireReusableUIComponents", dependencies: ["WireDesign", "WireFoundation"]),
        .testTarget(name: "WireReusableUIComponentsTests", dependencies: ["WireReusableUIComponents"]),

        .target(name: "WireMainNavigation"),
        .testTarget(name: "WireMainNavigationTests", dependencies: ["WireMainNavigation"]),

        .target(name: "WireConversationListNavigation"),
        .testTarget(name: "WireConversationListNavigationTests", dependencies: ["WireConversationListNavigation"]),

        .target(name: "WireAccountImage", dependencies: ["WireFoundation"]),
        .testTarget(name: "WireAccountImageTests", dependencies: ["WireAccountImage", "WireFoundation"]),

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
