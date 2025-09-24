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

@testable import WireDataModel
import XCTest

final class RemoveCoreCryptoKeysUseCaseTests: XCTestCase {

    private let sut: RemoveCoreCryptoKeysUseCase!
    private let userID = UUID()
    private let mockItem = MockKeychainItem()
    private let ccItem1 = CoreCryptoKeychainItem(uniqueKeyId: UUID(), userID: userID)
    private let ccItem2 = CoreCryptoKeychainItem(uniqueKeyId: UUID(), userID: userID)

    override func setUp() {
        super.setUp()
        sut = RemoveCoreCryptoKeysUseCase()
    }
    
    override func tearDown() {
        sut = nil
        deleteKeychainItems()
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
        XCTAssertNotNil(try? KeychainManager.fetchItem(mockItem.id))
        XCTAssertNil(try? KeychainManager.fetchItem(ccItem1.id))
        XCTAssertNil(try? KeychainManager.fetchItem(ccItem2.id))
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
            kSecReturnData: true,
        ]
    }
    
    func setQuery(value: some Any) -> [CFString: Any] { {
        [
            kSecClass: kSecClassKey,
            kSecAttrApplicationTag: tag,
            kSecValueData: value,
        ]
    }
}
