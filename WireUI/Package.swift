// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WireUI",
    defaultLocalization: "en",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library(name: "WireDesign", targets: ["WireDesign"]),
        .library(name: "WireReusableUIComponents", targets: ["WireReusableUIComponents"]),
        .library(name: "WireUIFoundation", targets: ["WireUIFoundation"]),
        .library(name: "WireAccountImage", targets: ["WireAccountImage"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.1.0"),
        .package(name: "WireFoundation", path: "../WireFoundation")
    ],
    targets: [
        .target(name: "WireDesign"),
        .testTarget(
            name: "WireDesignTests",
            dependencies: ["WireDesign"]
        ),

        .target(
            name: "WireReusableUIComponents",
            dependencies: [
                "WireDesign",
                .product(name: "WireFoundation", package: "WireFoundation")
            ]
        ),
        .testTarget(
            name: "WireReusableUIComponentsTests",
            dependencies: [
                "WireReusableUIComponents",
                .product(name: "WireTestingPackage", package: "WireFoundation")
            ]
        ),

        .target(name: "WireUIFoundation", dependencies: ["WireDesign"]),
        .testTarget(
            name: "WireUIFoundationTests",
            dependencies: [
                "WireUIFoundation",
                .product(name: "WireTestingPackage", package: "WireFoundation")
            ]
        ),

        .target(name: "WireAccountImage", dependencies: ["WireFoundation"]),
        .testTarget(
            name: "WireAccountImageTests",
            dependencies: [
                "WireAccountImage",
                .product(name: "WireTestingPackage", package: "WireFoundation")
            ]
        )
    ]
)

for target in package.targets {
    target.swiftSettings = [
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("GlobalConcurrency"),
        .enableExperimentalFeature("StrictConcurrency")
    ]
}
