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

import Foundation
import XCTest
@testable import WireDataModel

class CoreCryptoCallbacksTests: XCTestCase {

    func test_HardcodedValues() async {
        // Given
        let sut = CoreCryptoCallbacksImpl()

        // When
        let authorizeResult = await sut.authorize(
            conversationId: .random(),
            clientId: .random()
        )

        let userAuthorizeResult = await sut.userAuthorize(
            conversationId: .random(),
            externalClientId: .random(),
            existingClients: [.random()]
        )

        let clientIsExistingGroupUserResult = await sut.clientIsExistingGroupUser(
            conversationId: .random(),
            clientId: .random(),
            existingClients: [.random()],
            parentConversationClients: [.random()]
        )

        // Then
        XCTAssertTrue(authorizeResult)
        XCTAssertTrue(userAuthorizeResult)
        XCTAssertTrue(clientIsExistingGroupUserResult)
    }

}
