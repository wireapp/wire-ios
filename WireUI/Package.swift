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
        .library(name: "WireMainNavigation", targets: ["WireMainNavigation"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.2.0"),
        .package(name: "WireFoundation", path: "../WireFoundation")
    ],
    targets: [
        .target(name: "WireDesign", dependencies: ["WireFoundation"]),
        .testTarget(name: "WireDesignTests", dependencies: ["WireDesign", WireTestingPackage]),

        .target(name: "WireReusableUIComponents", dependencies: ["WireDesign", "WireFoundation"]),
        .testTarget(name: "WireReusableUIComponentsTests", dependencies: ["WireReusableUIComponents", WireTestingPackage]),

        .target(name: "WireMainNavigation", dependencies: ["WireDesign"]),
        .testTarget(name: "WireMainNavigationTests", dependencies: ["WireMainNavigation", WireTestingPackage]),

        .target(name: "WireAccountImage", dependencies: ["WireFoundation"]),
        .testTarget(name: "WireAccountImageTests", dependencies: ["WireAccountImage", WireTestingPackage]),

        .target(name: "WireSidebar", dependencies: ["WireFoundation"]),
        .testTarget(name: "WireSidebarTests", dependencies: ["WireSidebar", WireTestingPackage])
    ]
)

for target in package.targets {
    target.plugins = (target.plugins ?? []) + [SnapshotTestReferenceDirectoryPlugin]
    target.swiftSettings = (target.swiftSettings ?? []) + [
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("GlobalConcurrency"),
        .enableExperimentalFeature("StrictConcurrency")
    ]
}
