// swift-tools-version: 6.0

import Foundation
import PackageDescription

// Temporary local package replacing integration of CoreCrypto via Carthage
let package = Package(
    name: "WireCoreCrypto",
    platforms: [.iOS("16.4"), .macOS(.v12)],
    products: [
        .library(
            name: "WireCoreCrypto",
            targets: ["WireCoreCrypto"]
        ),
        .library(
            name: "WireCoreCryptoUniffi",
            targets: ["WireCoreCryptoUniffi"]
        )
    ],
    dependencies: [],
    targets: [
        .binaryTarget(
            name: "WireCoreCrypto",
            url: "https://github.com/wireapp/core-crypto/releases/download/v9.1.2/WireCoreCrypto.xcframework.zip",
            checksum: "152fa5e1f43c05c283106df2ab51267092d8b92f02b15debc91f8b237dda1490"
        ),
        // this is an internal dependency to WireCoreCrypto but currently needs to explictly
        // added as a dependency due to limitations of Swift packages.
        .binaryTarget(
            name: "WireCoreCryptoUniffi",
            url: "https://github.com/wireapp/core-crypto/releases/download/v9.1.2/WireCoreCryptoUniffi.xcframework.zip",
            checksum: "bf5a9b2cc90e1311f245fe0772530230e49a330a43cb688be5a2e2f6c6dd0f87"
        )
    ]
)
