// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "WireLogging",
    platforms: [.iOS("16.4"), .macOS(.v12)],
    products: [
        .library(name: "WireLogging", targets: ["WireLogging"])
    ],
    targets: [
        .target(name: "WireLogging")
    ]
)

for target in package.targets {
    target.swiftSettings = (target.swiftSettings ?? []) + [
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("ExistentialAny")
    ]
}
