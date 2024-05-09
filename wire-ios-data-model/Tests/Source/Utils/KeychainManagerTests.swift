//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

@testable import WireDataModel
import XCTest

class KeychainManagerTests: XCTestCase {

    var account: Account!

    override func setUpWithError() throws {
        account = Account(userName: "John Doe", userIdentifier: UUID())
    }

    override func tearDownWithError() throws {
        let item = DatabaseEARKeyDescription(accountID: account.userIdentifier, label: "foo")
        try? KeychainManager.deleteItem(item)
        account = nil
    }

    func testEncryptionKeyGenerateSuccessfully() throws {

        // Given
        let numberOfBytes: UInt = 32

        // When I have generated a key
        let key = try KeychainManager.generateKey(numberOfBytes: numberOfBytes)

        // Then key should not be nil
        XCTAssertNotNil(key, "Result must have some data bytes.")
    }

    func testPublicPrivateKeyPairIsGeneratedSuccessfully() throws {
        assertPublicPrivateKeyPairGeneration(accessLevel: .moreRestrictive)
        assertPublicPrivateKeyPairGeneration(accessLevel: .lessRestrictive)
    }

    func assertPublicPrivateKeyPairGeneration(accessLevel: KeychainManager.AccessLevel) {
        // Given
        let item = DatabaseEARKeyDescription(accountID: account.userIdentifier, label: "foo")

        do {
            // When I have generated Public Private KeyPair
            let KeyPair = try KeychainManager.generatePublicPrivateKeyPair(
                identifier: item.id,
                accessLevel: accessLevel
            )

            // Then KeyPair should not be nil
            XCTAssertNotNil(KeyPair, "Public Private KeyPair should be created successfully.")

        } catch {
            XCTFail("Failed to create Public Private KeyPair.")
        }
    }

    func testKeychainItemsStoreSuccessfully() throws {

        // Given I have generated a key
        let item = DatabaseEARKeyDescription(accountID: account.userIdentifier, label: "foo")
        let key = try KeychainManager.generateKey()
        XCTAssertNotNil(key, "Failed to generate the key.")

        // When I store the key
        try KeychainManager.storeItem(item, value: key)

        // Then when I fetch the key it's not nil
        let fetchItem: Data = try KeychainManager.fetchItem(item)
        XCTAssertNotNil(fetchItem, "Item should be fetch successfully.")
    }

    func testKeychainItemsFetchedSuccessfully() throws {

        // Given I have generated a key and successfully stored it
        let item = DatabaseEARKeyDescription(accountID: account.userIdentifier, label: "foo")
        let key = try KeychainManager.generateKey()
        try KeychainManager.storeItem(item, value: key)

        // When I fetch the key
        let fetchedItem: Data = try KeychainManager.fetchItem(item)

        // Then the key is not nil and equal to the one I stored.
        XCTAssertNotNil(key, "Failed to generate the key.")
        XCTAssertEqual(fetchedItem, key)
    }

    func testKeychainItemsDeleteSuccessfully() throws {
        // Given I have generated a key and successfully stored it.
        let item = DatabaseEARKeyDescription(accountID: account.userIdentifier, label: "foo")

        let key = try KeychainManager.generateKey()
        XCTAssertNotNil(key, "Failed to generate the key.")
        try KeychainManager.storeItem(item, value: key)

        // When I delete the key
        try KeychainManager.deleteItem(item)

        // Then fetching the key throws Error
        XCTAssertThrowsError(try KeychainManager.fetchItem(item) as Data, "Deleted item should not supposed to fetch again.")
    }
}
