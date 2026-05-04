//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

final class RemoveCoreCryptoKeysUseCaseTests: XCTestCase {

    private let userID = UUID()

    private var sut: RemoveCoreCryptoKeysUseCase!
    private var mockItem: MockKeychainItem!
    private var ccItem1: CoreCryptoKeychainItem!
    private var ccItem2: CoreCryptoKeychainItem!

    override func setUp() {
        super.setUp()
        sut = RemoveCoreCryptoKeysUseCase()
        mockItem = MockKeychainItem()
        ccItem1 = CoreCryptoKeychainItem(uniqueKeyId: UUID(), userID: userID)
        ccItem2 = CoreCryptoKeychainItem(uniqueKeyId: UUID(), userID: userID)
    }

    override func tearDown() {
        deleteKeychainItems()

        sut = nil
        mockItem = nil
        ccItem1 = nil
        ccItem2 = nil

        super.tearDown()
    }

    private func deleteKeychainItems() {
        try? KeychainManager.deleteItem(mockItem)
        try? KeychainManager.deleteItem(ccItem1)
        try? KeychainManager.deleteItem(ccItem2)
    }

    func test_itRemovesMatchingKeysOnly() throws {
        // Given
        try KeychainManager.storeItem(mockItem, value: Data())
        try KeychainManager.storeItem(ccItem1, value: Data())
        try KeychainManager.storeItem(ccItem2, value: Data())

        // When
        try sut.invoke(userID: userID)

        // Then
        XCTAssertNotNil(try? KeychainManager.fetchItem(mockItem))
        XCTAssertNil(try? KeychainManager.fetchItem(ccItem1))
        XCTAssertNil(try? KeychainManager.fetchItem(ccItem2))
    }

}

struct MockKeychainItem: KeychainItemProtocol {

    private let uuid = UUID()

    var id: String {
        "mock.keychain.key.\(uuid)"
    }

    var tag: Data {
        id.data(using: .utf8)!
    }

    var getQuery: [CFString: Any] {
        [
            kSecClass: kSecClassKey,
            kSecAttrApplicationTag: tag,
            kSecReturnData: true
        ]
    }

    func setQuery(value: some Any) -> [CFString: Any] {
        [
            kSecClass: kSecClassKey,
            kSecAttrApplicationTag: tag,
            kSecValueData: value
        ]
    }
}
