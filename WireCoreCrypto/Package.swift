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
<<<<<<< HEAD
            url: "https://github.com/wireapp/core-crypto/releases/download/v9.2.1/WireCoreCrypto.xcframework.zip",
            checksum: "a87a1b88626174918d107af911d54518d313ec182ca4d314b4a5271dacc46139"
=======
            url: "https://github.com/wireapp/core-crypto/releases/download/v10.1.1/WireCoreCrypto.xcframework.zip",
            checksum: "67444590076124d73cf1524c035c2d4a7be1d2122cc53c99e75dee23128951cd"
>>>>>>> ed0c5277aa (chore: bump Core Crypto to 10.1.1 - WPB-27753 (#5094))
        ),
        // this is an internal dependency to WireCoreCrypto but currently needs to explicitly
        // added as a dependency due to limitations of Swift packages.
        .binaryTarget(
            name: "WireCoreCryptoUniffi",
<<<<<<< HEAD
            url: "https://github.com/wireapp/core-crypto/releases/download/v9.2.1/WireCoreCryptoUniffi.xcframework.zip",
            checksum: "db991bfd31595bc02efa7521561ec7c6c581ca072db2b71a820ff7b7a8fd0a6d"
=======
            url: "https://github.com/wireapp/core-crypto/releases/download/v10.1.1/WireCoreCryptoUniffi.xcframework.zip",
            checksum: "a9583c7c8fda3306ec5577652c4b24e4717c632b45e58b808d904ed344231585"
>>>>>>> ed0c5277aa (chore: bump Core Crypto to 10.1.1 - WPB-27753 (#5094))
        )
    ]
)
