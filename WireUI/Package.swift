// swift-tools-version: 5.10

import PackageDescription

let WireTestingPackage = Target.Dependency.product(name: "WireTestingPackage", package: "WireFoundation")

let package = Package(
    name: "WireUI",
    defaultLocalization: "en",
    platforms: [.iOS("16.4"), .macOS(.v12)],
    products: [
        .library(name: "WireAccountImageUI", targets: ["WireAccountImageUI"]),
        .library(name: "WireConversationListUI", targets: ["WireConversationListUI"]),
        .library(name: "WireDesign", targets: ["WireDesign"]),
        .library(name: "WireFolderPickerUI", targets: ["WireFolderPickerUI"]),
        .library(name: "WireIndividualToTeamMigrationUI", targets: ["WireIndividualToTeamMigrationUI"]),
        .library(name: "WireMainNavigationUI", targets: ["WireMainNavigationUI"]),
        .library(name: "WireMoveToFolderUI", targets: ["WireMoveToFolderUI"]),
        .library(name: "WireMoveToFolderUISupport", targets: ["WireMoveToFolderUISupport"]),
        .library(name: "WireReusableUIComponents", targets: ["WireReusableUIComponents"]),
        .library(name: "WireReusableUIComponentsSupport", targets: ["WireReusableUIComponentsSupport"]),
        .library(name: "WireSettingsUI", targets: ["WireSettingsUI"]),
        .library(name: "WireSettingsUISupport", targets: ["WireSettingsUISupport"]),
        .library(name: "WireSidebarUI", targets: ["WireSidebarUI"]),
        .library(name: "WireMultiBackendUI", targets: ["WireMultiBackendUI"]),
        .library(name: "WireMultiBackendUISupport", targets: ["WireMultiBackendUISupport"]),
        .library(name: "WireLocators", targets: ["WireLocators"])
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.1.0"),
        .package(name: "WireDomainPackage", path: "../WireDomain"),
        .package(name: "WireFoundation", path: "../WireFoundation"),
        .package(path: "../WireLogging"),
        .package(path: "../WirePlugins")
    ],
    targets: [
        .target(
            name: "WireLocators",
            dependencies: [],
            path: "Sources/WireLocators"
        ),
        .target(
            name: "WireAccountImageUI",
            dependencies: ["WireDesign", "WireFoundation", "WireLocators"]
        ),
        .testTarget(name: "WireAccountImageUITests", dependencies: ["WireAccountImageUI", "WireFoundation"]),

        .target(name: "WireConversationListUI"),
        .testTarget(name: "WireConversationListUITests", dependencies: ["WireConversationListUI"]),

        .target(name: "WireDesign", dependencies: ["WireFoundation", "WireLocators"]),
        .testTarget(name: "WireDesignTests", dependencies: ["WireDesign"]),

        .target(name: "WireFolderPickerUI", dependencies: ["WireReusableUIComponents", "WireLocators"]),

        .target(
            name: "WireMultiBackendUI",
            dependencies: ["WireDesign", "WireAccountImageUI", "WireReusableUIComponents", "WireLocators"],
            plugins: [.plugin(name: "SwiftGenPlugin", package: "WirePlugins")]
        ),
        .target(
            name: "WireMultiBackendUISupport",
            dependencies: ["WireMultiBackendUI", "WireLocators"],
            plugins: [
                .plugin(name: "SourceryPlugin", package: "WirePlugins")
            ]
        ),
        .testTarget(name: "WireMultiBackendUITests", dependencies: ["WireMultiBackendUI"]),

        .target(
            name: "WireIndividualToTeamMigrationUI",
            dependencies: [
                .product(name: "WireDomainPackage", package: "WireDomainPackage"),
                "WireFoundation",
                "WireReusableUIComponents"
            ]
        ),
        .testTarget(name: "WireIndividualToTeamMigrationUITests", dependencies: ["WireIndividualToTeamMigrationUI"]),

        .target(
            name: "WireMainNavigationUI",
            dependencies: ["WireLocators"]
        ),
        .testTarget(name: "WireMainNavigationUITests", dependencies: ["WireMainNavigationUI"]),

        .target(
            name: "WireMoveToFolderUI",
            dependencies: ["WireFoundation", "WireReusableUIComponents", "WireLocators"]
        ),
        .target(
            name: "WireMoveToFolderUISupport",
            dependencies: ["WireMoveToFolderUI", "WireLocators"],
            plugins: [
                .plugin(name: "SourceryPlugin", package: "WirePlugins")
            ]
        ),
        .testTarget(name: "WireMoveToFolderUITests", dependencies: ["WireMoveToFolderUI", "WireMoveToFolderUISupport"]),

        .target(
            name: "WireReusableUIComponents",
            dependencies: ["WireDesign", "WireFoundation", "WireLocators"],
            plugins: [.plugin(name: "SwiftGenPlugin", package: "WirePlugins")]
        ),
        .target(
            name: "WireReusableUIComponentsSupport",
            dependencies: ["WireReusableUIComponents"],
            plugins: [
                .plugin(name: "SourceryPlugin", package: "WirePlugins")
            ]
        ),
        .testTarget(name: "WireReusableUIComponentsTests", dependencies: ["WireReusableUIComponents"]),

        .target(
            name: "WireSettingsUI",
            dependencies: [
                "WireDesign",
                .product(name: "WireDomainPackage", package: "WireDomainPackage"),
                "WireFoundation",
                .product(name: "WireLegacyLogging", package: "WireLogging"),
                "WireReusableUIComponents",
                "WireLocators"
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
        .testTarget(name: "WireSettingsUITests", dependencies: [
            .product(name: "WireFoundationSupport", package: "WireFoundation"),
            "WireSettingsUI",
            "WireSettingsUISupport"
        ]),

        .target(
            name: "WireSidebarUI",
            dependencies: ["WireFoundation", "WireLocators"],
            plugins: [.plugin(name: "SwiftGenPlugin", package: "WirePlugins")]
        ),
        .testTarget(name: "WireSidebarUITests", dependencies: ["WireSidebarUI"])
    ]
)

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
