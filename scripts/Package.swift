// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Scripts",
    targets: [
        .binaryTarget(
            name: "SwiftLintBinary",
            url: "https://github.com/realm/SwiftLint/releases/download/0.53.0/SwiftLintBinary-macos.artifactbundle.zip",
            checksum: "03416a4f75f023e10f9a76945806ddfe70ca06129b895455cc773c5c7d86b73e"
        ),
        .binaryTarget(
          name: "swiftgen",
          url: "https://github.com/SwiftGen/SwiftGen/releases/download/6.6.2/swiftgen-6.6.2.artifactbundle.zip",
          checksum: "7586363e24edcf18c2da3ef90f379e9559c1453f48ef5e8fbc0b818fbbc3a045"
        ),
        .binaryTarget(
            name: "sourcery",
            url: "https://github.com/krzysztofzablocki/Sourcery/releases/download/2.1.2/sourcery-2.1.2.artifactbundle.zip",
            checksum: "550c5a6a63b321bcd2ac595595cf6943efd09ce23d1ebba640b2598a4a1106a3"
        )
    ]
)
