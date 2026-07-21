// swift-tools-version: 6.0

import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "WireMockable",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "WireMockable", targets: ["WireMockable"])
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "601.0.0")
    ],
    targets: [
        .macro(
            name: "WireMockableMacros",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftDiagnostics", package: "swift-syntax")
            ]
        ),
        .target(
            name: "WireMockable",
            dependencies: ["WireMockableMacros"]
        ),
        .testTarget(
            name: "WireMockableTests",
            dependencies: [
                "WireMockableMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax")
            ]
        )
    ]
)

for target in package.targets {
    target.swiftSettings = (target.swiftSettings ?? []) + [
        .enableUpcomingFeature("ExistentialAny")
    ]
}
