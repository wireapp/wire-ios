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

class MLSClientIdTests: ZMConversationTestsBase {

    func test_itCreatesALowercasedClientId() {
        // GIVEN
        let userID = "57ce2cb2-601f-11ed-9b6a-0242ac120002"
        let clientID = "db151d3b837bb92"
        let domain = "example.wire.com"

        // WHEN
        let sut = MLSClientID(
            userID: userID.uppercased(),
            clientID: clientID.uppercased(),
            domain: domain.uppercased()
        )

        // THEN
        let expectedID = "\(userID):\(clientID)@\(domain)"
        XCTAssertEqual(sut.string, expectedID)
    }

}
