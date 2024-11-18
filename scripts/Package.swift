// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// How to add/update packages?
//
// 1. Go to GitHub repository, the latest release.
// 2. Copy url of <*.artifactbundle.zip> and enter here as 'url'.
// 3. Download <*.artifactbundle.zip>, open terminal, go to the folder like '~/Downloads/'.
// 4. Run 'swift package compute-checksum <*.artifactbundle.zip>', copy the checksum and enter here as 'checksum'.
// 5. Save this file.
// 6. Go to repository './scripts/'.
// 7. Run `swift package update` to fetch new artifacts.

let package = Package(
    name: "Scripts",
    targets: [
        .executableTarget(
            name: "TrimStringCatalogs",
            path: "./TrimStringCatalogs",
            exclude: ["./Tests.swift", "./TestResources"],
            sources: ["./main.swift"]
        ),
        .testTarget(
            name: "TrimStringCatalogsTests",
            dependencies: ["TrimStringCatalogs"],
            path: "./TrimStringCatalogs",
            exclude: ["./main.swift"],
            sources: ["./Tests.swift"],
            resources: [
                .copy("./TestResources/Trimmed_xcstrings"),
                .copy("./TestResources/Untrimmed_xcstrings")
            ]
        ),

        .binaryTarget(
            name: "LicensePlist",
            url: "https://github.com/mono0926/LicensePlist/releases/download/3.25.1/LicensePlistBinary-macos.artifactbundle.zip",
            checksum: "a80181eeed49396dae5d3ce6fc339f33a510299b068fd6b4f507483db78f7f30"
        ),
        .binaryTarget(
            name: "SwiftLintBinary",
            url: "https://github.com/realm/SwiftLint/releases/download/0.57.0/SwiftLintBinary-macos.artifactbundle.zip",
            checksum: "a1bbafe57538077f3abe4cfb004b0464dcd87e8c23611a2153c675574b858b3a"
        ),
        .binaryTarget(
            name: "swiftformat",
            url: "https://github.com/nicklockwood/SwiftFormat/releases/download/0.54.5/swiftformat.artifactbundle.zip",
            checksum: "39b4530054003cf9c668b0f9391b977fc13215925aaaaa3038d6379099b8486d"
        )
    ]
)
