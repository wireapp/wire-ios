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

import Foundation
@testable import WireDataModel

final class AccountTests: XCTestCase {

    func testThatAccountsAreEqualWhenNotImportantPropertiesAreDifferent() {
        // given
        let userName = "Bruno", team = "Wire", id = UUID.create(), image = Data(), count = 14

        let account = Account(
            userName: userName,
            userIdentifier: id,
            teamName: team,
            imageData: image,
            teamImageData: image,
            unreadConversationCount: count
        )

        let sameAccount = Account(
            userName: "",
            userIdentifier: id,
            teamName: "",
            imageData: nil,
            teamImageData: nil,
            unreadConversationCount: 0
        )

        XCTAssertEqual(account, sameAccount)
    }

    func testThatKeychainItemsAreDeleted() throws {
        // Given
        let id = UUID()
        let sut = Account(userName: "Alice", userIdentifier: id)
        let item = AppLockController.PasscodeKeychainItem(userId: id)
        let data = try XCTUnwrap(Data("passscode".utf8))

        try Keychain.storeItem(item, value: data)
        XCTAssertNoThrow(try Keychain.fetchItem(item))

        // When
        sut.deleteKeychainItems()

        // Then
        XCTAssertThrowsError(try Keychain.fetchItem(item))
    }

}
