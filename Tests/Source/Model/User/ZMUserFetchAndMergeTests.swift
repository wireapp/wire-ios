//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

class ZMUserFetchAndMergeTests: ModelObjectsTests {
    func testThatItMergesDuplicatesWhenFetching() {
        self.syncMOC.performGroupedBlockAndWait {
            // Given
            let remoteIdentifier = UUID()

            let user1 = ZMUser.insert(in: self.syncMOC, name: "one")
            user1.remoteIdentifier = remoteIdentifier
            let user2 = ZMUser.insert(in: self.syncMOC, name: "two")
            user2.remoteIdentifier = remoteIdentifier
            self.syncMOC.saveOrRollback()

            let beforeMerge = ZMUser.fetchAll(with: remoteIdentifier, in: self.syncMOC)
            XCTAssertEqual(beforeMerge.count, 2)

            // when
            let user = ZMUser.fetchAndMerge(with: remoteIdentifier, createIfNeeded: false, in: self.syncMOC)

            // then
            XCTAssertNotNil(user)
            XCTAssertEqual(user?.remoteIdentifier, remoteIdentifier)

            let afterMerge = ZMUser.fetchAll(with: remoteIdentifier, in: self.syncMOC)
            XCTAssertEqual(afterMerge.count, 1)
            XCTAssertEqual(user, afterMerge.first)
        }

    }

}
