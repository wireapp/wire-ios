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
            url: "https://github.com/wireapp/core-crypto/releases/download/v9.2.1/WireCoreCrypto.xcframework.zip",
            checksum: "a87a1b88626174918d107af911d54518d313ec182ca4d314b4a5271dacc46139"
        ),
        // this is an internal dependency to WireCoreCrypto but currently needs to explictly
        // added as a dependency due to limitations of Swift packages.
        .binaryTarget(
            name: "WireCoreCryptoUniffi",
            url: "https://github.com/wireapp/core-crypto/releases/download/v9.2.1/WireCoreCryptoUniffi.xcframework.zip",
            checksum: "db991bfd31595bc02efa7521561ec7c6c581ca072db2b71a820ff7b7a8fd0a6d"
        )
    ]
)
