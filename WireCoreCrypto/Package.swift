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
            url: "https://github.com/wireapp/core-crypto/releases/download/v6.0.1/WireCoreCrypto.xcframework.zip",
            checksum: "a75e11dd3ff4ec4ec6f455d8512a9f0b0d8b98dba12f62672ed97aa4c2072e81"
        ),
        // this is an internal dependency to WireCoreCrypto but currently needs to explictly
        // added as a dependency due to limitations of Swift packages.
        .binaryTarget(
            name: "WireCoreCryptoUniffi",
            url: "https://github.com/wireapp/core-crypto/releases/download/v6.0.1/WireCoreCryptoUniffi.xcframework.zip",
            checksum: "93113420d7194ea38e5b7a6a4ab4827e7e6793f01d3e6b6df103db9e56732a03"
        )
    ]
)
