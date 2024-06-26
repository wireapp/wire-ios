// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// How to update packages?
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
        .binaryTarget(
            name: "LicensePlist",
            url: "https://github.com/mono0926/LicensePlist/releases/download/3.25.1/LicensePlistBinary-macos.artifactbundle.zip",
            checksum: "a80181eeed49396dae5d3ce6fc339f33a510299b068fd6b4f507483db78f7f30"
        ),
        .binaryTarget(
            name: "SwiftLintBinary",
            url: "https://github.com/realm/SwiftLint/releases/download/0.54.0/SwiftLintBinary-macos.artifactbundle.zip",
            checksum: "963121d6babf2bf5fd66a21ac9297e86d855cbc9d28322790646b88dceca00f1"
        ),
        .binaryTarget(
          name: "swiftgen",
          url: "https://github.com/SwiftGen/SwiftGen/releases/download/6.6.2/swiftgen-6.6.2.artifactbundle.zip",
          checksum: "7586363e24edcf18c2da3ef90f379e9559c1453f48ef5e8fbc0b818fbbc3a045"
        )
    ]
)
