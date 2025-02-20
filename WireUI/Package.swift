// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let WireTestingPackage = Target.Dependency.product(name: "WireTestingPackage", package: "WireFoundation")

let Foundation = Feature(name: "WireFoundation")
let Design = Feature(name: "WireDesign", dependencies: [Foundation])
let AccountImageUI = Feature(name: "WireAccountImageUI", dependencies: [Design, Foundation])

let package = Package(
    name: "WireUI",
    defaultLocalization: "en",
    platforms: [.iOS(.v16), .macOS(.v12)],
    products: [
        AccountImageUI.library,
        .library(name: "WireConversationListUI", targets: ["WireConversationListUI"]),
        .library(name: "WireConversationUI", targets: ["WireConversationUI"]),
        .library(name: "WireDesign", targets: ["WireDesign"]),
        .library(name: "WireFolderPickerUI", targets: ["WireFolderPickerUI"]),
        .library(name: "WireIndividualToTeamMigrationUI", targets: ["WireIndividualToTeamMigrationUI"]),
        .library(name: "WireMainNavigationUI", targets: ["WireMainNavigationUI"]),
        .library(name: "WireMoveToFolderUI", targets: ["WireMoveToFolderUI"]),
        .library(name: "WireMoveToFolderUISupport", targets: ["WireMoveToFolderUISupport"]),
        .library(name: "WireReusableUIComponents", targets: ["WireReusableUIComponents"]),
        .library(name: "WireSettingsUI", targets: ["WireSettingsUI"]),
        .library(name: "WireSettingsUISupport", targets: ["WireSettingsUISupport"]),
        .library(name: "WireSidebarUI", targets: ["WireSidebarUI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.1.0"),
        .package(path: "../WireAnalytics"),
        .package(name: "WireDomainPackage", path: "../WireDomain"),
        .package(name: "WireFoundation", path: "../WireFoundation"),
        .package(path: "../WireLogging"),
        .package(path: "../WirePlugins")
    ],
    targets: [
        AccountImageUI.target,
        AccountImageUI.testTarget,

        .target(name: "WireConversationListUI"),
        .testTarget(name: "WireConversationListUITests", dependencies: ["WireConversationListUI"]),

        .target(name: "WireConversationUI"),
        .testTarget(name: "WireConversationUITests", dependencies: ["WireConversationUI"]),

        .target(name: "WireDesign", dependencies: ["WireFoundation"]),
        .testTarget(name: "WireDesignTests", dependencies: ["WireDesign"]),

        .target(name: "WireFolderPickerUI", dependencies: ["WireReusableUIComponents"]),

        .target(
            name: "WireIndividualToTeamMigrationUI",
            dependencies: [
                "WireAnalytics",
                .product(name: "WireDomainPackage", package: "WireDomainPackage"),
                "WireFoundation",
                "WireReusableUIComponents"
            ]
        ),
        .testTarget(name: "WireIndividualToTeamMigrationUITests", dependencies: ["WireIndividualToTeamMigrationUI"]),

        .target(name: "WireMainNavigationUI"),
        .testTarget(name: "WireMainNavigationUITests", dependencies: ["WireMainNavigationUI"]),

        .target(name: "WireMoveToFolderUI", dependencies: ["WireFoundation", "WireReusableUIComponents"]),
        .target(
            name: "WireMoveToFolderUISupport",
            dependencies: ["WireMoveToFolderUI"],
            plugins: [
                .plugin(name: "SourceryPlugin", package: "WirePlugins")
            ]
        ),
        .testTarget(name: "WireMoveToFolderUITests", dependencies: ["WireMoveToFolderUI", "WireMoveToFolderUISupport"]),

        .target(
            name: "WireReusableUIComponents",
            dependencies: ["WireDesign", "WireFoundation"],
            plugins: [.plugin(name: "SwiftGenPlugin", package: "WirePlugins")]
        ),
        .testTarget(name: "WireReusableUIComponentsTests", dependencies: ["WireReusableUIComponents"]),

        .target(
            name: "WireSettingsUI",
            dependencies: [
                "WireDesign",
                .product(name: "WireDomainPackage", package: "WireDomainPackage"),
                "WireFoundation",
                "WireLogging",
                "WireReusableUIComponents",
            ],
            plugins: [.plugin(name: "SwiftGenPlugin", package: "WirePlugins")]
        ),
        .target(
            name: "WireSettingsUISupport",
            dependencies: ["WireSettingsUI"],
            plugins: [
                .plugin(name: "SourceryPlugin", package: "WirePlugins")
            ]
        ),
        .testTarget(name: "WireSettingsUITests", dependencies: ["WireSettingsUI", "WireSettingsUISupport"]),

        .target(
            name: "WireSidebarUI",
            dependencies: ["WireFoundation"],
            plugins: [.plugin(name: "SwiftGenPlugin", package: "WirePlugins")]
        ),
        .testTarget(name: "WireSidebarUITests", dependencies: ["WireSidebarUI"])
    ]
)

struct Feature {
    var name: String
    var dependencies: [Feature] = []
    var library: Product {
        .library(name: name, targets: [name])
    }
    var target: Target {
        .target(name: name, dependencies: dependencies.map { .init(stringLiteral: $0.name) })
    }
    var testTarget: Target {
        .testTarget(name: name + "Tests", dependencies: [self].map { .init(stringLiteral: $0.name) })
    }
}

for target in package.targets {
    if target.isTest {
        target.dependencies += [WireTestingPackage]
    }
    target.swiftSettings = (target.swiftSettings ?? []) + [
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("GlobalConcurrency"),
        .enableExperimentalFeature("StrictConcurrency")
    ]
}
