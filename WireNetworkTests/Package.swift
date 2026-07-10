// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "WireNetworkTests",
    platforms: [.iOS(.v17), .macOS(.v12)],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", exact: "1.18.3"),
        .package(path: "../WireFoundation"),
        .package(path: "../WireNetwork"),
        .package(path: "../WireNetworkSupport")
    ],
    targets: [
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
                .process("APIs/Blacklist/Resources"),
                .process("APIs/Rest/AccountsAPI/Resources"),
                .process("APIs/Rest/AuthenticationAPI/Resources"),
                .process("APIs/Rest/BackendMetadataAPI/Resources"),
                .process("APIs/Rest/ConnectionsAPI/Resources"),
                .process("APIs/Rest/ConversationsAPI/Resources"),
                .process("APIs/Rest/FeatureConfigsAPI/Resources"),
                .process("APIs/Rest/MeetingsAPI/Resources"),
                .process("APIs/Rest/MLSAPI/Resources"),
                .process("APIs/Rest/Search/Resources"),
                .process("APIs/Rest/SelfUserAPI/Resources"),
                .process("APIs/Rest/TeamsAPI/Resources"),
                .process("APIs/Rest/UpdateEventsAPI/Resources"),
                .process("APIs/Rest/UserClientsAPI/Resources"),
                .process("APIs/Rest/UserPropertiesAPI/Resources"),
                .process("APIs/Rest/UsersAPI/Resources"),
                .process("Authentication/Resources"),
                .process("Backend/Resources"),
                .process("Network/PushChannel/Resources"),
                .process("UpdateEvent/Resources")
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
