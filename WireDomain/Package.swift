// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WireDomainPackage",
    platforms: [.iOS(.v16), .macOS(.v12)],
    products: [
        .library(name: "WireDomainPackage", targets: ["WireDomainPkg"])
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.1.0")
    ],
    targets: [
        .target(
            name: "WireDomainPkg",
            path: "./Sources/WireDomain",
            sources: [
                "./UseCases/Protocols/CreateLegacyBackupError.swift",
                "./UseCases/Protocols/ImportBackupError.swift",
                "./UseCases/Protocols/ImportBackupProgress.swift",
                "./UseCases/Protocols/ImportBackupUseCaseProtocol.swift",
                "./UseCases/Protocols/IndividualToTeamMigrationUseCaseProtocol.swift"
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
