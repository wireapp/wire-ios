//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

import GenericMessageProtocol
import XCTest

@testable import WireSyncEngine

class ZMLocalNotificationTests: MessagingTest {

    typealias ZMLocalNotification = WireSyncEngine.ZMLocalNotification

    var sender: ZMUser!
    var selfUser: ZMUser!
    var otherUser1: ZMUser!
    var otherUser2: ZMUser!
    var userWithNoName: ZMUser!
    var oneOnOneConversation: ZMConversation!
    var groupConversation: ZMConversation!
    var groupConversationWithoutUserDefinedName: ZMConversation!
    var groupConversationWithoutName: ZMConversation!
    var invalidConversation: ZMConversation!

    override func setUp() {
        super.setUp()
        selfUser = ZMUser.selfUser(in: uiMOC)
        selfUser.remoteIdentifier = UUID.create()
        sender = insertUser(with: UUID.create(), name: "Super User")
        otherUser1 = insertUser(with: UUID.create(), name: "Other User1")
        otherUser2 = insertUser(with: UUID.create(), name: "Other User2")
        userWithNoName = insertUser(with: UUID.create(), name: nil)
        oneOnOneConversation = insertConversation(
            with: UUID.create(),
            name: "Super Conversation",
            type: .oneOnOne,
            mutedMessages: .none,
            otherParticipants: [selfUser, sender]
        )
        groupConversation = insertConversation(
            with: UUID.create(),
            name: "Super Conversation",
            type: .group,
            mutedMessages: .none,
            otherParticipants: [sender, otherUser1]
        )

        // an empty conversation will have no meaninful display name
        groupConversationWithoutName = insertConversation(
            with: UUID.create(),
            name: nil,
            type: .group,
            mutedMessages: .none,
            otherParticipants: []
        )
        groupConversationWithoutUserDefinedName = insertConversation(
            with: UUID.create(),
            name: nil,
            type: .group,
            mutedMessages: .none,
            otherParticipants: [sender, otherUser1]
        )
        invalidConversation = insertConversation(
            with: UUID.create(),
            name: nil,
            type: .invalid,
            mutedMessages: .none,
            otherParticipants: []
        )
        uiMOC.saveOrRollback()
        _ = waitForAllGroupsToBeEmpty(withTimeout: 0.5)
    }

    override func tearDown() {
        sender = nil
        otherUser1 = nil
        otherUser2 = nil
        userWithNoName = nil
        oneOnOneConversation = nil
        groupConversation = nil
        groupConversationWithoutName = nil
        groupConversationWithoutUserDefinedName = nil
        invalidConversation = nil
        selfUser.remoteIdentifier = nil
        _ = waitForAllGroupsToBeEmpty(withTimeout: 0.5)
        super.tearDown()
    }

    // MARK: - Helpers

    func insertUser(with remoteID: UUID, name: String?) -> ZMUser {
        var user: ZMUser!
        performPretendingUiMocIsSyncMoc {
            user = ZMUser.insertNewObject(in: self.uiMOC)
            user.name = name
            user.remoteIdentifier = remoteID
            self.uiMOC.saveOrRollback()
        }
        return user
    }

    func insertConversation(
        with remoteID: UUID,
        name: String?,
        type: ZMConversationType,
        mutedMessages: MutedMessageTypes,
        otherParticipants: [ZMUser]
    ) -> ZMConversation {
        var conversation: ZMConversation!
        conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = remoteID
        conversation.userDefinedName = name
        conversation.conversationType = type
        conversation.mutedMessageTypes = mutedMessages
        conversation.lastServerTimeStamp = Date()
        conversation.lastReadServerTimeStamp = conversation.lastServerTimeStamp
        conversation?.addParticipantsAndUpdateConversationState(
            users: Set(otherParticipants + [selfUser]),
            role: nil
        )
        uiMOC.saveOrRollback()
        return conversation
    }
}
