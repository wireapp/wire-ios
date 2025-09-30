// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WireCalling",
    defaultLocalization: "en",
    platforms: [.iOS("16.4"), .macOS(.v12)],
    products: [
        .library(name: "WireCallingDomain", targets: ["WireCallingDomain"]),
        .library(name: "WireCallingAssembly", targets: ["WireCallingAssembly"]),
        .library(name: "WireCallingUI", targets: ["WireCallingUI"])
    ],
    
    targets: [
        .target(
            name: "WireCallingDomain",
            dependencies: [
                "WireFoundation",
                "WireLogging"
            ]
        ),
        .target(
            name: "WireCallingData",
            dependencies: [
                "WireData",
                "WireCallingDomain",
                "WireLogging"
            ]
        ),
        .target(
            name: "WireCallingAssembly",
            dependencies: [
                "WireCallingDomain",
                "WireCallingUI",
                "WireCallingData"
            ]
        ),
        .target(
            name: "WireCallingUI",
            dependencies: [
                "WireCallingDomain",
                .product(name: "WireDesign", package: "WireUI"),
                .product(name: "WireReusableUIComponents", package: "WireUI"),
                "WireFoundation"
            ],
            plugins: [.plugin(name: "SwiftGenPlugin", package: "WirePlugins")]
        ),
    ]
)
for target in package.targets {
    target.swiftSettings = (target.swiftSettings ?? []) + [
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("ExistentialAny")
    ]
}
