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
            url: "https://github.com/wireapp/core-crypto/releases/download/v10.2.0/WireCoreCrypto.xcframework.zip",
            checksum: "313e0b5e46cfe77d2af3a200a74515082a0593e3d745fc535c13982789771628"
        ),
        // this is an internal dependency to WireCoreCrypto but currently needs to explicitly
        // added as a dependency due to limitations of Swift packages.
        .binaryTarget(
            name: "WireCoreCryptoUniffi",
            url: "https://github.com/wireapp/core-crypto/releases/download/v10.2.0/WireCoreCryptoUniffi.xcframework.zip",
            checksum: "91e533f240b604a404a2344fdadc7e19d9515825e4b09adb36232e30d063c00f"
        )
    ]
)
