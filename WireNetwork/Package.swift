// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "WireNetwork",
    platforms: [.iOS("16.4"), .macOS(.v12)],
    products: [
        .library(name: "WireNetwork", targets: ["WireNetwork"]),
        .library(name: "WireNetworkSupport", targets: ["WireNetworkSupport"])
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.1.0"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", exact: "1.18.3"),
        .package(path: "../WirePlugins"),
        .package(path: "../WireLogging"),
        .package(path: "../WireFoundation")
    ],
    targets: [
        .target(
            name: "WireNetwork",
            dependencies: [
                "WireFoundation",
                .product(name: "WireLegacyLogging", package: "WireLogging"),
                .product(name: "WireCrypto", package: "WireFoundation")
            ]
        ),
        .target(
            name: "WireNetworkSupport",
            dependencies: ["WireNetwork"],
            plugins: [
                .plugin(name: "SourceryPlugin", package: "WirePlugins")
            ]
        ),
        .testTarget(
            name: "WireNetworkTests",
            dependencies: [
                "WireNetwork",
                "WireNetworkSupport",
                .product(name: "WireCrypto", package: "WireFoundation"),
                .product(name: "WireTestingPackage", package: "WireFoundation"),
                .product(name: "WireFoundationSupport", package: "WireFoundation"),
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ],
            resources: [
                .process("APIs/Rest/AuthenticationAPI/Resources"),
                .process("APIs/Rest/AccountsAPI/Resources"),
                .process("APIs/Rest/BackendMetadataAPI/Resources"),
                .process("APIs/Rest/ConnectionsAPI/Resources"),
                .process("APIs/Rest/ConversationsAPI/Resources"),
                .process("APIs/Rest/MLSAPI/Resources"),
                .process("APIs/Rest/TeamsAPI/Resources"),
                .process("APIs/Rest/UpdateEventsAPI/Resources"),
                .process("APIs/Rest/UsersAPI/Resources"),
                .process("UpdateEvent/Resources"),
                .process("APIs/Rest/FeatureConfigsAPI/Resources"),
                .process("APIs/Rest/UserPropertiesAPI/Resources"),
                .process("APIs/Rest/SelfUserAPI/Resources"),
                .process("APIs/Rest/UserClientsAPI/Resources"),
                .process("Network/PushChannel/Resources"),
                .process("Authentication/Resources"),
                .process("Backend/Resources"),
                .process("APIs/Blacklist/Resources")
            ]
        )
    ]
)

for target in package.targets {
    // remove this once we updated the Sourcery stencil to support existential any
    guard target.name != "WireNetworkSupport" else { continue }

    target.swiftSettings = [
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("GlobalConcurrency"),
        .enableExperimentalFeature("StrictConcurrency")
    ]
}
