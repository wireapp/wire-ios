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
                "WireLogging",
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
                .process("APIs/AuthenticationAPI/Resources"),
                .process("APIs/AccountsAPI/Resources"),
                .process("APIs/BackendMetadataAPI/Resources"),
                .process("APIs/ConnectionsAPI/Resources"),
                .process("APIs/ConversationsAPI/Resources"),
                .process("APIs/MLSAPI/Resources"),
                .process("APIs/TeamsAPI/Resources"),
                .process("APIs/UpdateEventsAPI/Resources"),
                .process("APIs/UsersAPI/Resources"),
                .process("UpdateEvent/Resources"),
                .process("APIs/FeatureConfigsAPI/Resources"),
                .process("APIs/UserPropertiesAPI/Resources"),
                .process("APIs/SelfUserAPI/Resources"),
                .process("APIs/UserClientsAPI/Resources"),
                .process("Network/PushChannel/Resources"),
                .process("Authentication/Resources"),
                .process("Backend/Resources")
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
