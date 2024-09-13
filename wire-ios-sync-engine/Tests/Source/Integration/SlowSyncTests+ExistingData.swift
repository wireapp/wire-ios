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

import WireTesting
import XCTest

class SlowSyncTests_ExistingData: IntegrationTest {
    override func setUp() {
        super.setUp()

        createSelfUserAndConversation()
        createExtraUsersAndConversations()
    }

    // MARK: - Slow sync with existing data

    func testThatConversationIsDeleted_WhenDiscoveredToBeDeletedDuringSlowSync() {
        // GIVEN
        XCTAssertTrue(login())

        let conversation = conversation(for: groupConversation)!

        performRemoteChangesExludedFromNotificationStream { session in
            session.delete(self.groupConversation)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertFalse(conversation.isDeletedRemotely)

        // WHEN
        performSlowSync()

        // THEN
        XCTAssertTrue(conversation.isDeletedRemotely)
    }

    func testThatSelfUserLeavesConversation_WhenDiscoveredToBeInaccessibledDuringResyncResources() {
        // GIVEN
        XCTAssertTrue(login())

        let conversation = conversation(for: groupConversation)!

        performRemoteChangesExludedFromNotificationStream { _ in
            self.groupConversation.removeUsers(by: self.user2, removedUser: self.selfUser)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertTrue(conversation.isSelfAnActiveMember)

        // WHEN
        performResyncResources()

        // THEN
        XCTAssertFalse(conversation.isSelfAnActiveMember)
    }
}
