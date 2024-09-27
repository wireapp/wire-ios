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

final class ZMConversationTests_MLS: ZMConversationTestsBase {
    override func tearDown() {
        BackendInfo.isFederationEnabled = false
        super.tearDown()
    }

    func testThatItFetchesConversationWithGroupID() throws {
        syncMOC.performGroupedAndWait {
            // Given
            BackendInfo.isFederationEnabled = false
            let groupID = MLSGroupID(.init([1, 2, 3]))
            let conversation = groupID.createConversation(in: syncMOC)

            // When
            let fetchedConversation = ZMConversation.fetch(with: groupID, in: syncMOC)

            // Then
            XCTAssertEqual(fetchedConversation, conversation)
        }
    }

    func testThatItFetchesConversationWithGroupID_FederationEnabled() throws {
        syncMOC.performGroupedAndWait {
            // Given
            BackendInfo.isFederationEnabled = true
            let groupID = MLSGroupID(.init([1, 2, 3]))
            let conversation = groupID.createConversation(in: syncMOC)

            // When
            let fetchedConversation = ZMConversation.fetch(with: groupID, in: syncMOC)

            // Then
            XCTAssertEqual(fetchedConversation, conversation)
        }
    }

    func testThatItFetchesConversationWithMLSGroupStatus() throws {
        try syncMOC.performAndWait { [self] in
            // Given
            BackendInfo.isFederationEnabled = false
            let groupID = MLSGroupID(.init([1, 2, 3]))
            let pendingConversation = groupID.createConversation(in: syncMOC)
            pendingConversation.mlsStatus = .pendingJoin
            let readyConversation = groupID.createConversation(in: syncMOC)
            readyConversation.mlsStatus = .ready

            // When
            let pendingConversations = try ZMConversation.fetchConversationsWithMLSGroupStatus(
                mlsGroupStatus: .pendingJoin,
                in: syncMOC
            )
            let readyConversations = try ZMConversation.fetchConversationsWithMLSGroupStatus(
                mlsGroupStatus: .ready,
                in: syncMOC
            )

            // Then
            XCTAssertEqual(pendingConversations, [pendingConversation])
            XCTAssertEqual(readyConversations, [readyConversation])
        }
    }
}

// MARK: - Migration releated fetch requests

final class ZMConversationTests_MLS_Migration: ModelObjectsTests {
    func test_fetchAllTeamGroupConversations_messageProtocolProteus() async throws {
        // Given
        let conversations = try await syncMOC.perform { [syncMOC] in

            // ensure selfUser has a teamIdentifier set
            let selfUser = ZMUser.selfUser(in: syncMOC)
            selfUser.teamIdentifier = .init()

            // create specific conversations
            let conversations = (0 ..< 4).map { _ in
                let conversation = MLSGroupID.random().createConversation(in: syncMOC)
                conversation.messageProtocol = .proteus
                conversation.conversationType = .group
                conversation.teamRemoteIdentifier = selfUser.teamIdentifier
                return conversation
            }
            // only conversations[0] should be fetched successfully
            conversations[1].messageProtocol = .mls
            conversations[2].conversationType = .`self`
            conversations[3].teamRemoteIdentifier = .init()
            try syncMOC.save()
            return conversations
        }

        // When
        let fetchedConversations = try await syncMOC.perform { [syncMOC] in
            try ZMConversation.fetchAllTeamGroupConversations(messageProtocol: .proteus, in: syncMOC)
        }

        // Then
        XCTAssertEqual(fetchedConversations, [conversations[0]])
    }

    func test_fetchAllTeamGroupConversations_messageProtocolMixed() async throws {
        // GIVEN
        let conversations = try await syncMOC.perform { [syncMOC] in

            // ensure selfUser has a teamIdentifier set
            let selfUser = ZMUser.selfUser(in: syncMOC)
            selfUser.teamIdentifier = .init()

            // create specific conversations
            let conversations = (0 ..< 4).map { _ in
                let conversation = MLSGroupID.random().createConversation(in: syncMOC)
                conversation.messageProtocol = .mixed
                conversation.conversationType = .group
                conversation.teamRemoteIdentifier = selfUser.teamIdentifier
                return conversation
            }

            // only conversations[0] should be fetched successfully
            conversations[1].conversationType = .`self`
            conversations[2].conversationType = .`self`
            conversations[3].teamRemoteIdentifier = .init()

            try syncMOC.save()
            return conversations
        }

        // WHEN
        let fetchedConversations = try await syncMOC.perform { [syncMOC] in
            try ZMConversation.fetchAllTeamGroupConversations(messageProtocol: .mixed, in: syncMOC)
        }

        // THEN
        XCTAssertEqual(fetchedConversations, [conversations[0]])
    }
}

// MARK: - MLSGroupID Helper

extension MLSGroupID {
    fileprivate func createConversation(in managedObjectContext: NSManagedObjectContext) -> ZMConversation {
        let conversation = ZMConversation.insertNewObject(in: managedObjectContext)
        conversation.remoteIdentifier = NSUUID.create()
        conversation.mlsGroupID = self
        conversation.messageProtocol = .mls
        XCTAssert(managedObjectContext.saveOrRollback())
        return conversation
    }
}
