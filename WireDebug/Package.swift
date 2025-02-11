// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WireDebug",
    defaultLocalization: "en",
    platforms: [.iOS(.v16), .macOS(.v12)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(name: "WireViewsDebugUI", targets: ["WireViewsDebugUI"])
    ],
    dependencies: [
        .package(name: "WireAuthentication", path: "../WireAuthentication"),
        .package(name: "WireCells", path: "../WireCells"),
        .package(name: "WireDomainPackage", path: "../WireDomain"),
        .package(name: "WireFoundation", path: "../WireFoundation"),
        .package(path: "../WireUI")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "WireViewsDebugUI",
            dependencies: [
                .product(name: "WireAuthenticationUI", package: "WireAuthentication"),
                .product(name: "WireDomainPackage", package: "WireDomainPackage"),
                "WireFoundation",
                .product(name: "WireReusableUIComponents", package: "WireUI")
            ]
        )
    ]
)
