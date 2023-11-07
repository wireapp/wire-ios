// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Scripts",
    products: [
        .plugin(
            name: "RunSwiftLint",
            targets: ["RunSwiftLint"]),
    ],
    dependencies: [
        .package(url: "https://github.com/realm/SwiftLint.git", exact: "0.53.0"),
    ],
    targets: [
        .plugin(
            name: "RunSwiftLint",
            capability: .command(
                intent: .custom(
                    verb: "run-swiftlint",
                    description: "prints code style and conventions related warnings and errors"
                )
            ),
            dependencies: [/*"SwiftLint"*/],
            sources: ["RunSwiftLint.swift"]
        ),
    ]
)
