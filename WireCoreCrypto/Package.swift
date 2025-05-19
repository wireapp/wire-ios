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
            checksum: "d291cf8ef997b1414448890446893465bb2147f23b396e92e6a8098de948b7f9"
        ),
        // this is an internal dependency to WireCoreCrypto but currently needs to explictly
        // added as a dependency due to limitations of Swift packages.
        .binaryTarget(
            name: "WireCoreCryptoUniffi",
            url: "https://github.com/wireapp/core-crypto/releases/download/v6.0.1/WireCoreCryptoUniffi.xcframework.zip",
            checksum: "4931c7473c83e157f5c89a6e6dda9a087d746e97f9b0a4443b106cb56e5b8789"
        )
    ]
)
