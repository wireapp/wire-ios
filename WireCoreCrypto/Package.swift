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
            url: "https://github.com/wireapp/core-crypto/releases/download/v7.0.2/WireCoreCrypto.xcframework.zip",
            checksum: "c16e4bd5616b1bf154db64b8d00b16ced69a6b5cd3eb66f61cf9f2feb871a867"
        ),
        // this is an internal dependency to WireCoreCrypto but currently needs to explictly
        // added as a dependency due to limitations of Swift packages.
        .binaryTarget(
            name: "WireCoreCryptoUniffi",
            url: "https://github.com/wireapp/core-crypto/releases/download/v7.0.2/WireCoreCryptoUniffi.xcframework.zip",
            checksum: "669fda445f209b07c784a07dc5fbeda31b0ffb0336e9f13867195f9be8120e16"
        )
    ]
)
