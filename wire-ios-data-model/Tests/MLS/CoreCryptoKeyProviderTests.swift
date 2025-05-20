//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

import Foundation
import XCTest
@testable import WireDataModel

class CoreCryptoKeyProviderTests: XCTestCase {

    override func tearDown() {
        super.tearDown()
        try? KeychainManager.deleteItem(CoreCryptoKeychainItem())
        try? KeychainManager.deleteItem(CoreCryptoKeychainItemV2())
    }

    // MARK: Fetching & creating key

    func test_itFetchesCoreCryptoKeyV2() async throws {
        // GIVEN
        let sut = CoreCryptoKeyProvider()

        let item = CoreCryptoKeychainItemV2()
        let expectedKey = try KeychainManager.generateKey(numberOfBytes: 32)
        try KeychainManager.storeItem(item, value: expectedKey)

        // WHEN
        let key = try await sut.coreCryptoKey(createIfNeeded: false, path: "")

        // THEN
        XCTAssertEqual(key, expectedKey)
    }

    func test_itDoesntCreateCoreCryptoKey_WhenNotNeeded() async {
        // GIVEN
        let sut = CoreCryptoKeyProvider()

        // WHEN
        await XCTAssertThrowsErrorAsync {
            _ = try await sut.coreCryptoKey(createIfNeeded: false, path: "")
        }

        // THEN
        XCTAssertNil(try? KeychainManager.fetchItem(CoreCryptoKeychainItem()))
        XCTAssertNil(try? KeychainManager.fetchItem(CoreCryptoKeychainItemV2()))
    }

    func test_itCreatesCoreCryptoKeyV2_WhenNeeded() async throws {
        // GIVEN
        let sut = CoreCryptoKeyProvider()

        // WHEN
        let key = try await sut.coreCryptoKey(createIfNeeded: true, path: "")

        // THEN
        XCTAssertNotNil(key)

        let storedKey: Data? = try? KeychainManager.fetchItem(CoreCryptoKeychainItemV2())
        XCTAssertNotNil(storedKey)
        XCTAssertEqual(key, storedKey)
    }

    func test_itCreatesCryptoKeyV2_ifKeyV1Exists() async throws {
        // GIVEN
        let sut = CoreCryptoKeyProvider()

        let item = CoreCryptoKeychainItem()
        let expectedKey = try KeychainManager.generateKey(numberOfBytes: 32)
        try KeychainManager.storeItem(item, value: expectedKey)

        // WHEN
        let oldStoredKey: Data? = try? KeychainManager.fetchItem(CoreCryptoKeychainItem())
        XCTAssertNotNil(oldStoredKey)

        let newdKey: Data? = try? KeychainManager.fetchItem(CoreCryptoKeychainItemV2())
        XCTAssertNil(newdKey)

        let key = try await sut.coreCryptoKey(createIfNeeded: true, path: "")

        // THEN
        let newStoredKey: Data? = try? KeychainManager.fetchItem(CoreCryptoKeychainItemV2())
        XCTAssertNotNil(newStoredKey)
        XCTAssertEqual(key, newStoredKey)
    }

}
