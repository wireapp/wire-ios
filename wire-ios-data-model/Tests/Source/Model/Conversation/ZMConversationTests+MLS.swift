//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

final class ZMConversationTests_MLS: ZMConversationTestsBase {

    override func tearDown() {
        BackendInfo.isFederationEnabled = false
        super.tearDown()
    }

    func testThatItFetchesConversationWithGroupID() {
        syncMOC.performGroupedBlockAndWait { [self] in
            // Given
            BackendInfo.isFederationEnabled = false
            let groupID = MLSGroupID([1, 2, 3])
            let conversation = self.createConversation(groupID: groupID)

            // When
            let fetchedConversation = ZMConversation.fetch(with: groupID, in: syncMOC)

            // Then
            XCTAssertEqual(fetchedConversation, conversation)
        }
    }

    func testThatItFetchesConversationWithGroupID_FederationEnabled() {
        syncMOC.performGroupedBlockAndWait { [self] in
            // Given
            BackendInfo.isFederationEnabled = true
            let groupID = MLSGroupID([1, 2, 3])
            let conversation = self.createConversation(groupID: groupID)

            // When
            let fetchedConversation = ZMConversation.fetch(with: groupID, in: syncMOC)

            // Then
            XCTAssertEqual(fetchedConversation, conversation)
        }
    }

    func testThatItFetchesConversationWithMLSGroupStatus() {
        syncMOC.performGroupedBlockAndWait { [self] in
            // Given
            BackendInfo.isFederationEnabled = false
            let groupID = MLSGroupID([1, 2, 3])
            let pendingConversation = self.createConversation(groupID: groupID)
            pendingConversation?.mlsStatus = .pendingJoin
            let readyConversation = self.createConversation(groupID: groupID)
            readyConversation?.mlsStatus = .ready

            // When
            let pendingConversations = ZMConversation.fetchConversationsWithMLSGroupStatus(mlsGroupStatus: .pendingJoin, in: syncMOC)
            let readyConversations = ZMConversation.fetchConversationsWithMLSGroupStatus(mlsGroupStatus: .ready, in: syncMOC)

            // Then
            XCTAssertEqual(pendingConversations, [pendingConversation])
            XCTAssertEqual(readyConversations, [readyConversation])
        }
    }

    private func createConversation(groupID: MLSGroupID) -> ZMConversation? {
        let conversation = ZMConversation.insertNewObject(in: syncMOC)
        conversation.remoteIdentifier = NSUUID.create()
        conversation.mlsGroupID = groupID
        conversation.messageProtocol = .mls
        XCTAssert(syncMOC.saveOrRollback())
        return conversation
    }

}
