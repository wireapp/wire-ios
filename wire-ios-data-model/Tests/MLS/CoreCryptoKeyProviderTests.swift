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
    }

    // MARK: Fetching & creating key

    func test_itFetchesCoreCryptoKey() async throws {
        // GIVEN
        let sut = CoreCryptoKeyProvider()

        let item = CoreCryptoKeychainItem()
        let expectedKey = try KeychainManager.generateKey(numberOfBytes: 32)
        try KeychainManager.storeItem(item, value: expectedKey)

        // WHEN
        let key = try await sut.coreCryptoKey(createIfNeeded: false, path: "")

        // THEN
        XCTAssertEqual(key, expectedKey)
    }

//    func test_itDoesntCreateCoreCryptoKey_WhenNotNeeded() async {
//        // GIVEN
//        let sut = CoreCryptoKeyProvider()
//
//        // WHEN
//        //XCTAssertThrowsError(try await sut.coreCryptoKey(createIfNeeded: false, path: ""))
//        do {
//            _ = try await sut.coreCryptoKey(createIfNeeded: false, path: "")
//        } catch let error as CoreCryptoKeyProvider.Error {
//            XCTAssertEqual(error, .failedToFetchItemFromKeychain(errSecItemNotFound))
//        } catch {
//            XCTFail("Unexpected error type: \(error)")
//        }
//
//        // THEN
//        XCTAssertNil(try? KeychainManager.fetchItem(CoreCryptoKeychainItem()))
//    }

    func test_itCreatesCoreCryptoKey_WhenNeeded() async throws {
        // GIVEN
        let sut = CoreCryptoKeyProvider()

        // WHEN
        let key = try await sut.coreCryptoKey(createIfNeeded: true, path: "")

        // THEN
        XCTAssertNotNil(key)

        let storedKey: Data? = try? KeychainManager.fetchItem(CoreCryptoKeychainItem())
        XCTAssertNotNil(storedKey)
        XCTAssertEqual(key, storedKey)
    }

}
