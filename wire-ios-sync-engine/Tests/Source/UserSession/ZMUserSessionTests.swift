//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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
import WireDataModelSupport
import WireSyncEngine

class ZMUserSessionSwiftTests: ZMUserSessionTestsBase {

    func testThatItMarksTheConversationsAsRead() throws {
        // given
        let conversationsRange: CountableClosedRange = 1...10

        let conversations: [ZMConversation] = conversationsRange.map { _ in
            return self.sut.insertConversationWithUnreadMessage()
        }

        try self.uiMOC.save()

        // when
        self.sut.markAllConversationsAsRead()

        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        self.uiMOC.refreshAllObjects()
        XCTAssertEqual(conversations.filter { $0.firstUnreadMessage != nil }.count, 0)
    }

    func test_itPerformsPeriodicMLSUpdates_AfterQuickSync() {
        // given
        mockMLSService.performPendingJoins_MockMethod = {}
        mockMLSService.commitPendingProposals_MockMethod = {}

        // MLS client has been registered
        self.syncMOC.performAndWait {
            let selfUserClient = createSelfClient()
            selfUserClient.mlsPublicKeys = UserClient.MLSPublicKeys(ed25519: "somekey")
            selfUserClient.needsToUploadMLSPublicKeys = false
            syncMOC.saveOrRollback()
        }

        // when
        sut.didFinishQuickSync()

        // then
        XCTAssertFalse(mockMLSService.performPendingJoins_Invocations.isEmpty)
        XCTAssertFalse(mockMLSService.uploadKeyPackagesIfNeeded_Invocations.isEmpty)
    }
}
