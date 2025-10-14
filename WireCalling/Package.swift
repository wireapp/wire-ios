// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let WireTestingPackage = Target.Dependency.product(name: "WireTestingPackage", package: "WireFoundation")

let package = Package(
    name: "WireCalling",
    defaultLocalization: "en",
    platforms: [.iOS("16.4"), .macOS(.v12)],
    products: [
        .library(name: "WireCallingDomain", targets: ["WireCallingDomain"]),
        .library(name: "WireCallingAssembly", targets: ["WireCallingAssembly"]),
        .library(name: "WireCallingUI", targets: ["WireCallingUI"])
    ],
    dependencies: [
        .package(name: "WireFoundation", path: "../WireFoundation"),
        .package(path: "../WirePlugins"),
        .package(path: "../WireLogging"),
        .package(name: "WireUI", path: "../WireUI")
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
            name: "WireCallingAssembly",
            dependencies: [
                "WireCallingDomain",
                "WireCallingUI"
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
        .testTarget(
            name: "WireCallingTests",
            dependencies: [
                "WireCallingDomain"
            ],
        ),
        .testTarget(
            name: "WireCallingUITests",
            dependencies: [
                "WireCallingUI",
                .product(name: "WireDesign", package: "WireUI")
            ],
        ),
    ]
)

for target in package.targets {
    if target.isTest {
        target.dependencies += [WireTestingPackage]
    }
}

for target in package.targets {
    target.swiftSettings = (target.swiftSettings ?? []) + [
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("ExistentialAny")
    ]
}
