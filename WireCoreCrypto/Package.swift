// swift-tools-version: 6.0

import Foundation
import PackageDescription

// Temporary local package replacing integration of CoreCrypto via Carthage
let package = Package(
    name: "WireCoreCrypto",
    platforms: [.iOS(.v17), .macOS(.v12)],
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
            // TODO: [WPB-27280] Replace this migration pin with the 11.x release containing core-crypto#2844 before merging.
            url: "https://github.com/wireapp/core-crypto/releases/download/v11.0.0/WireCoreCrypto.xcframework.zip",
            checksum: "312eaa1e662b03560d11112e900a17e779ab8716da96107a3ef802bb616bfc12"
        ),
        // this is an internal dependency to WireCoreCrypto but currently needs to explicitly
        // added as a dependency due to limitations of Swift packages.
        .binaryTarget(
            name: "WireCoreCryptoUniffi",
            url: "https://github.com/wireapp/core-crypto/releases/download/v11.0.0/WireCoreCryptoUniffi.xcframework.zip",
            checksum: "78dbb6f57578ebec2c6cbee09d4d40719c1260ec1a6a200ab81ad53630877b83"
        )
    ]
)
