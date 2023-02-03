//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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

import XCTest
@testable import WireDataModel

class KeychainManagerTests: XCTestCase {

    var account: Account!

    override func setUpWithError() throws {
        account = Account(userName: "John Doe", userIdentifier: UUID())
    }

    override func tearDownWithError() throws {
        try EncryptionKeys.deleteKeys(for: account)
        account = nil
    }

    func testEncryptionKeyGenerateSuccessfully() throws {

        // Given
        let numberOfBytes: UInt = 32

        do {
            // When I have generated a key
            let key = try KeychainManager.generateKey(numberOfBytes: numberOfBytes)

            // Then key should not be nil
            XCTAssertNotNil(key, "Result must have some data bytes.")

        } catch {
            XCTFail("Failed to generate the key successfully.")
        }
    }

    func testPublicPrivateKeyPairIsGeneratedSuccessfully() throws {

        #if targetEnvironment(simulator) && swift(>=5.4)
        if #available(iOS 15, *) {
            XCTExpectFailure("Expect to fail on iOS 15 simulator. ref: https://wearezeta.atlassian.net/browse/SQCORE-1188")
        }
        #endif

        // Given
        let item = EncryptionKeys.KeychainItem.databaseKey(account)

        do {
            // When I have generated Public Private KeyPair
            let KeyPair = try KeychainManager.generatePublicPrivateKeyPair(identifier: item.uniqueIdentifier)

            // Then KeyPair should not be nil
            XCTAssertNotNil(KeyPair, "Public Private KeyPair should be created successfully.")

        } catch {
            XCTFail("Failed to create Public Private KeyPair.")
        }
    }

    func testKeychainItemsStoreSuccessfully() throws {
        do {
            // Given I have generated a key
            let item = EncryptionKeys.KeychainItem.databaseKey(account)
            let key = try KeychainManager.generateKey()
            XCTAssertNotNil(key, "Failed to generate the key.")

            // When I store the key
            try KeychainManager.storeItem(item, value: key)

            // Then when I fetch the key it's not nil
            let fetchItem: Data = try KeychainManager.fetchItem(item)
            XCTAssertNotNil(fetchItem, "Item should be fetch successfully.")

        } catch let error {
            XCTFail("Failed to store item with error: \(error).")
        }
    }

    func testKeychainItemsFetchedSuccessfully() throws {
        do {
            // Given I have generated a key and successfully stored it
            let item = EncryptionKeys.KeychainItem.databaseKey(account)
            let key = try KeychainManager.generateKey()
            try KeychainManager.storeItem(item, value: key)

            // When I fetch the key
            let fetchedItem: Data = try KeychainManager.fetchItem(item)

            // Then the key is not nil and equal to the one I stored.
            XCTAssertNotNil(key, "Failed to generate the key.")
            XCTAssertEqual(fetchedItem, key)

        } catch let error {
            XCTFail("Failed to fetch the item with error: \(error).")
        }
    }

    func testKeychainItemsDeleteSuccessfully() throws {
        // Given I have generated a key and successfully stored it.
        let item = EncryptionKeys.KeychainItem.databaseKey(account)

        do {
            let key = try KeychainManager.generateKey()
            XCTAssertNotNil(key, "Failed to generate the key.")
            try KeychainManager.storeItem(item, value: key)

            // When I delete the key
            try KeychainManager.deleteItem(item)

        } catch let error {
            XCTFail("Failed to Delete item with error: \(error).")
        }

        // Then fetching the key throws Error
        XCTAssertThrowsError(try KeychainManager.fetchItem(item) as Data, "Deleted item should not supposed to fetch again.")
    }
}
