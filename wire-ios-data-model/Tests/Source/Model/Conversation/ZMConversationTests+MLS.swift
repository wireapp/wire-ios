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

import XCTest

@testable import WireDataModel

final class ZMConversationTests_MLS: ZMConversationTestsBase {

    override func tearDown() {
        BackendInfo.isFederationEnabled = false
        super.tearDown()
    }

    func testThatItFetchesConversationWithGroupID() throws {
        try syncMOC.performGroupedAndWait { syncMOC in
            // Given
            BackendInfo.isFederationEnabled = false
            let groupID = MLSGroupID([1, 2, 3])
            let conversation = try groupID.createConversation(in: syncMOC)

            // When
            let fetchedConversation = ZMConversation.fetch(with: groupID, in: syncMOC)

            // Then
            XCTAssertEqual(fetchedConversation, conversation)
        }
    }

    func testThatItFetchesConversationWithGroupID_FederationEnabled() throws {
        try syncMOC.performGroupedAndWait { syncMOC in
            // Given
            BackendInfo.isFederationEnabled = true
            let groupID = MLSGroupID([1, 2, 3])
            let conversation = try groupID.createConversation(in: syncMOC)

            // When
            let fetchedConversation = ZMConversation.fetch(with: groupID, in: syncMOC)

            // Then
            XCTAssertEqual(fetchedConversation, conversation)
        }
    }

}

// MARK: - Migration releated fetch requests

final class ZMConversationTests_MLS_Migration: ModelObjectsTests {

    func test_fetchAllTeamGroupProteusConversations() throws {
        // Given
        let conversations = try syncMOC.performGroupedAndWait { syncMOC in

            // ensure selfUser has a teamIdentifier set
            let selfUser = ZMUser.selfUser(in: syncMOC)
            selfUser.teamIdentifier = .init()

            // create specific conversations
            let conversations = try (0..<4).map { _ in
                let conversation = try MLSGroupID.random().createConversation(in: syncMOC)
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
        let fetchedConversations = try syncMOC.performGroupedAndWait { syncMOC in
            try ZMConversation.fetchAllTeamGroupProteusConversations(in: syncMOC)
        }

        // Then
        XCTAssertEqual(fetchedConversations, [conversations[0]])
    }

}

// MARK: - MLSGroupID Helper

extension MLSGroupID {

    fileprivate func createConversation(in managedObjectContext: NSManagedObjectContext) throws -> ZMConversation {
        let conversation = ZMConversation.insertNewObject(in: managedObjectContext)
        conversation.remoteIdentifier = NSUUID.create()
        conversation.mlsGroupID = self
        try managedObjectContext.save()
        return conversation
    }

}
