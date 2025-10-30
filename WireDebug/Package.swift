// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "WireDebug",
    defaultLocalization: "en",
    platforms: [.iOS("16.4"), .macOS(.v12)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(name: "WireViewsDebugUI", targets: ["WireViewsDebugUI"])
    ],
    dependencies: [
        .package(name: "WireAuthentication", path: "../WireAuthentication"),
        .package(name: "WireMessaging", path: "../WireMessaging"),
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
                .product(name: "WireMessagingUI", package: "WireMessaging"),
                .product(name: "WireDomainPackage", package: "WireDomainPackage"),
                "WireFoundation",
                .product(name: "WireReusableUIComponents", package: "WireUI")
            ]
        )
    ]
)

for target in package.targets {
    target.swiftSettings = (target.swiftSettings ?? []) + [
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("ExistentialAny")
    ]
}
