// swift-tools-version: 5.10

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
            url: "https://github.com/mono0926/LicensePlist/releases/download/3.27.1/LicensePlistBinary-macos.artifactbundle.zip",
            checksum: "24e066b23da58275a89a83cae05bf40cad8a48faacf10facbfa5c350efe02608"
        ),
        .binaryTarget(
            name: "SwiftLintBinary",
            url: "https://github.com/realm/SwiftLint/releases/download/0.61.0/SwiftLintBinary.artifactbundle.zip",
            checksum: "b765105fa5c5083fbcd35260f037b9f0d70e33992d0a41ba26f5f78a17dc65e7"
        ),
        .binaryTarget(
            name: "swiftformat",
            url: "https://github.com/nicklockwood/SwiftFormat/releases/download/0.58.3/swiftformat.artifactbundle.zip",
            checksum: "349130edf42691b1e94f0a5f9a7914bbd38a817d462a63e41a88178908ec6479"
        )
    ]
)
