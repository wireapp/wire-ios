// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "WireAPI",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library(name: "WireAPI", targets: ["WireAPI"]),
        .library(name: "WireAPISupport", targets: ["WireAPISupport"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.1.0"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.17.4"),
        .package(path: "../SourceryPlugin"),
        .package(name: "WireFoundation", path: "../WireFoundation")
    ],
    targets: [
        .target(
            name: "WireAPI",
            dependencies: ["WireFoundation"]
        ),
        .target(
            name: "WireAPISupport",
            dependencies: ["WireAPI"],
            plugins: [
                .plugin(name: "SourceryPlugin", package: "SourceryPlugin")
            ]
        ),
        .testTarget(
            name: "WireAPITests",
            dependencies: [
                "WireAPI",
                "WireAPISupport",
                .product(name: "WireTestingPackage", package: "WireFoundation"),
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ],
            resources: [
                .process("APIs/BackendInfoAPI/Resources"),
                .process("APIs/ConnectionsAPI/Resources"),
                .process("APIs/ConversationsAPI/Resources"),
                .process("APIs/TeamsAPI/Resources"),
                .process("APIs/UpdateEventsAPI/Resources"),
                .process("APIs/UsersAPI/Resources"),
                .process("UpdateEvent/Resources"),
                .process("APIs/FeatureConfigsAPI/Resources"),
                .process("APIs/UserPropertiesAPI/Resources"),
                .process("APIs/SelfUserAPI/Resources"),
                .process("APIs/UserClientsAPI/Resources"),
                .process("Network/PushChannel/Resources")
            ]
        )
    ]
)

for target in package.targets {
    // remove this once we updated the Sourcery stencil to support existential any
    guard target.name != "WireAPISupport" else { continue }

    target.swiftSettings = [
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("GlobalConcurrency"),
        .enableExperimentalFeature("StrictConcurrency")
    ]
}
