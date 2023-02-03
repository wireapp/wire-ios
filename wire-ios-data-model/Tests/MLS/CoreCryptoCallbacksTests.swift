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

    func test_ClientIDBelongsToOneOfOtherClients() throws {
        // Given
        let sut = CoreCryptoCallbacksImpl()
        let userID1 = UUID.create().uuidString
        let userID2 = UUID.create().uuidString
        let domain = "example.com"

        let mlsClientID = MLSClientID(
            userID: userID1,
            clientID: "client1",
            domain: domain
        )

        let otherMLSClientIDs = [
            // Client from same user
            MLSClientID(
                userID: userID1,
                clientID: "client2",
                domain: domain
            ),
            // Client from another user
            MLSClientID(
                userID: userID2,
                clientID: "client3",
                domain: domain
            )
        ]

        let clientID = try XCTUnwrap(mlsClientID.string.data(using: .utf8)?.bytes)
        let otherClients = otherMLSClientIDs.compactMap {
            $0.string.data(using: .utf8)?.bytes
        }

        // When
        let result = sut.clientIsExistingGroupUser(
            clientId: clientID,
            existingClients: otherClients
        )

        // Then
        XCTAssertTrue(result)
    }

    func test_ClientIDDoesNotBelongToOneOfOtherClients() throws {
        // Given
        let sut = CoreCryptoCallbacksImpl()
        let userID1 = UUID.create().uuidString
        let userID2 = UUID.create().uuidString
        let domain1 = "example.com"
        let domain2 = "bar.com"

        let mlsClientID = MLSClientID(
            userID: userID1,
            clientID: "client1",
            domain: domain1
        )

        let otherMLSClientIDs = [
            // Client from another user
            MLSClientID(
                userID: userID1,
                clientID: "client2",
                domain: domain2
            ),
            // Client from another user
            MLSClientID(
                userID: userID2,
                clientID: "client3",
                domain: domain1
            )
        ]

        let clientID = try XCTUnwrap(mlsClientID.string.data(using: .utf8)?.bytes)
        let otherClients = otherMLSClientIDs.compactMap {
            $0.string.data(using: .utf8)?.bytes
        }

        // When
        let result = sut.clientIsExistingGroupUser(
            clientId: clientID,
            existingClients: otherClients
        )

        // Then
        XCTAssertFalse(result)
    }

}
