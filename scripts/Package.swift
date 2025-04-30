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
            url: "https://github.com/realm/SwiftLint/releases/download/0.59.1/SwiftLintBinary.artifactbundle.zip",
            checksum: "b9f915a58a818afcc66846740d272d5e73f37baf874e7809ff6f246ea98ad8a2"
        ),
        .binaryTarget(
            name: "swiftformat",
            url: "https://github.com/nicklockwood/SwiftFormat/releases/download/0.55.5/swiftformat.artifactbundle.zip",
            checksum: "2c6e8903b88ca94f621586a91617c89337f53460bb3db00e3de655f96895a1a8"
        )
    ]
)
