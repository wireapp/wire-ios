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
            url: "https://github.com/wireapp/core-crypto/releases/download/v7.0.1/WireCoreCrypto.xcframework.zip",
            checksum: "e14e4769b218aed66575abb3073e58b7c6457c5b8eca6ffc7b4bfd45f7a39f21"
        ),
        // this is an internal dependency to WireCoreCrypto but currently needs to explictly
        // added as a dependency due to limitations of Swift packages.
        .binaryTarget(
            name: "WireCoreCryptoUniffi",
            url: "https://github.com/wireapp/core-crypto/releases/download/v7.0.1/WireCoreCryptoUniffi.xcframework.zip",
            checksum: "0bed5f7b7dbbd6b62825cc89880bb3668261be4031fe2c7b4430a2cf83165ae7"
        )
    ]
)
