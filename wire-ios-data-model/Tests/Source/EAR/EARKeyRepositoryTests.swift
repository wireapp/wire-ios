//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

final class EARKeyRepositoryTests: XCTestCase {

    var sut: EARKeyRepository!

    // MARK: - Life cycle

    override func setUp() {
        super.setUp()
        sut = EARKeyRepository()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func legacyPublicKeyGetQuery(accountID: UUID) -> CFDictionary {
        let id = "com.wire.ear.public.\(accountID.transportString())"
        let tag = id.data(using: .utf8)!

        let attributes: [CFString: Any] = [
            kSecClass: kSecClassKey,
            kSecAttrApplicationTag: tag,
            kSecReturnRef: true
        ]

        return attributes as CFDictionary
    }

    private func existsLegacyPublicKey(accountID: UUID) throws -> Bool {
        do {
            let item = LegacyEARKey.publicKey(accountID: accountID)
            let _: SecKey = try KeychainManager.fetchItem(item)
            return true
        } catch KeychainManager.Error.failedToFetchItemFromKeychain(errSecItemNotFound) {
            return false
        }
    }

    // MARK: - Update legacy keys

    // given legacy keys exist, then we update their attributes.
    func test_UpdateLegacyPublicPrivateKeyPairLegacy_KeysExist() throws {
        // Given
        // legacy keys

        // When
        //

        // Then
        // legacy keys don't exist.
        // primary keys do exist.
    }

    func test_UpdateLegacyPublicPrivateKeyPair_LegacyKeysDontExist() throws {
        // Given
        let accountID = UUID.create()
        XCTAssertFalse(try existsLegacyPublicKey(accountID: accountID))

        // When
        
        try sut.updateLegacyPublicPrivateKeyPair(accountID: accountID)

        // Then
        // aborted early
    }

}
