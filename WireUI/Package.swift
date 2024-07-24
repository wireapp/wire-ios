// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WireUI",
    defaultLocalization: "en",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library(name: "WireDesign", targets: ["WireDesign"]),
        .library(name: "WireReusableUIComponents", targets: ["WireReusableUIComponents"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.1.0"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.16.0"),
        // .package(path: "../SourceryPlugin"),
        .package(path: "../WireTestingPackage")
    ],
    targets: [
        .target(
            name: "WireDesign",
            swiftSettings: swiftSettings,
            plugins: [
                // .plugin(name: "SourceryPlugin", package: "SourceryPlugin")
            ]
        ),
        .testTarget(
            name: "WireDesignTests",
            dependencies: [
                "WireDesign",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
            ],
            swiftSettings: swiftSettings
        ),

        .target(
            name: "WireReusableUIComponents",
            dependencies: ["WireDesign"],
            swiftSettings: swiftSettings,
            plugins: [
                // .plugin(name: "SourceryPlugin", package: "SourceryPlugin")
            ]
        ),
        .testTarget(
            name: "WireReusableUIComponentsTests",
            dependencies: [
                "WireReusableUIComponents",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
                .product(
                    name: "WireTestingPackage",
                    package: "WireTestingPackage"
                )
            ],
            swiftSettings: swiftSettings
        )
    ]
)

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ExistentialAny")
]
