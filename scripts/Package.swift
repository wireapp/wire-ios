// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// How to add/update packages?
// 
// 1. Go to GitHub repository, the latest release.
// 2. Copy url of <*.artifactbundle.zip> and enter here as 'url'.
// 3. Download <*.artifactbundle.zip>, open terminal, go to the folder like '~/Downloads/'.
// 4. Run 'swift package compute-checksum <*.artifactbundle.zip>', copy the checksum and enter here as 'checksum'.
// 5. Save this file.
// 6. Run `./setup.sh` script again.

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
            url: "https://github.com/realm/SwiftLint/releases/download/0.55.1/SwiftLintBinary-macos.artifactbundle.zip",
            checksum: "722a705de1cf4e0e07f2b7d2f9f631f3a8b2635a0c84cce99f9677b38aa4a1d6"
        ),
        .binaryTarget(
          name: "swiftgen",
          url: "https://github.com/SwiftGen/SwiftGen/releases/download/6.6.2/swiftgen-6.6.2.artifactbundle.zip",
          checksum: "7586363e24edcf18c2da3ef90f379e9559c1453f48ef5e8fbc0b818fbbc3a045"
        ),
        .binaryTarget(
            name: "swiftformat",
            url: "https://github.com/nicklockwood/SwiftFormat/releases/download/0.54.0/swiftformat.artifactbundle.zip",
            checksum: "edf4ed2f1664ad621ae71031ff915e0c6ef80ad66e87ea0e5a10c3580a27a6dd"
        )
    ]
)
