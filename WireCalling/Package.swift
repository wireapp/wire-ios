// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "WireCalling",
    defaultLocalization: "en",
    platforms: [.iOS("16.4"), .macOS(.v12)],
    products: [
        .library(name: "WireCallingUI", targets: ["WireCallingUI"])
    ],
    dependencies: [
        .package(path: "../WireFoundation"),
        .package(path: "../WireUI")
    ],
    targets: [
        .target(
            name: "WireCallingUI",
            dependencies: [
                .product(name: "WireDesign", package: "WireUI"),
                .product(name: "WireReusableUIComponents", package: "WireUI"),
                "WireFoundation"
            ],
        ),
        .testTarget(
            name: "WireCallingTests",
            dependencies: [
                "WireFoundation"
            ],
        ),
    ]
)
for target in package.targets {
    target.swiftSettings = (target.swiftSettings ?? []) + [
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("ExistentialAny")
    ]
}
