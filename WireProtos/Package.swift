// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "WireProtos",
    platforms: [.iOS("16.4"), .macOS(.v12)],
    products: [
        .library(name: "WireProtos", targets: ["WireProtos"]),
        .library(name: "WireProtosSupport", targets: ["WireProtosSupport"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.30.0"),
        .package(url: "https://github.com/caldrian/generic-message-proto.git", from: "1.53.0"),
//        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.1.0"),
//        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", exact: "1.18.3"),
        .package(path: "../WirePlugins")
    ],
    targets: [
        .target(
            name: "WireProtos",
            dependencies: [
                .product(name: "GenericMessage", package: "generic-message-proto"),
                .product(name: "SwiftProtobuf", package: "swift-protobuf")
            ]
        ),
        .testTarget(
            name: "WireProtosTests",
            dependencies: ["WireProtos", "WireProtosSupport"]
        ),
        .target(
            name: "WireProtosSupport",
            dependencies: ["WireProtos"],
            plugins: [.plugin(name: "SourceryPlugin", package: "WirePlugins")]
        )
    ]
)

for target in package.targets {
    target.swiftSettings = (target.swiftSettings ?? []) + [
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("ExistentialAny")
    ]
}
