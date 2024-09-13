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

import XCTest
@testable import WireDataModel

class UserClientTestsSafeLogging: ZMBaseManagedObjectTest {
    func testThatSafeRemoteIdentifierReturnsReadableHashOfRemoteIdentifier() {
        let uuid = UUID.create().transportString()
        syncMOC.performGroupedAndWait {
            let client = UserClient.insertNewObject(in: self.syncMOC)
            client.remoteIdentifier = uuid
            XCTAssertEqual(uuid.redactedAndTruncated(), client.safeRemoteIdentifier.safeForLoggingDescription)
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func testThatSafeRemoteIdentifierReturnsNilStringIfRemoteIdentifierIsNil() {
        syncMOC.performGroupedAndWait {
            let client = UserClient.insertNewObject(in: self.syncMOC)
            XCTAssertEqual("nil", client.safeRemoteIdentifier.safeForLoggingDescription)
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }
}
