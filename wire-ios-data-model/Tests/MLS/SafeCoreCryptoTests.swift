//
//  SafeCoreCryptoTests.swift
//  WireDataModelTests
//
//  Created by F on 22/02/2023.
//  Copyright © 2023 Wire Swiss GmbH. All rights reserved.
//

import Foundation
@testable import WireDataModel

func createTempFolder() -> URL {
    let url = URL(fileURLWithPath: [NSTemporaryDirectory(), UUID().uuidString].joined(separator: "/"))
    try! FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: [:])
    return url
}

class SafeCoreCryptoTests: ZMBaseManagedObjectTest {

    func test_safeFileContext() throws {
        let tempURL = createTempFolder()
        let sut = SafeFileContext(fileURL: tempURL)

        sut.acquireDirectoryLock()
        print("locked")
        sut.releaseDirectoryLock()
        print("unlocked")

    }
    func test_performDoesNotBlockWithMock() throws {

        let tempURL = createTempFolder()

        let sut = SafeCoreCrypto(coreCrypto: MockCoreCrypto(), coreCryptoConfiguration: .init(path: tempURL.path, key: "key", clientID: "id"))

        XCTAssertNoThrow(try sut.perform { mock in
            try mock.setCallbacks(callbacks: CoreCryptoCallbacksImpl())
        })

    }
}
