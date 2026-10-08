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

import Foundation

final class ZMConversationListDirectoryTests_Meeting: ZMBaseManagedObjectTest {

    var meetingConversation: ZMConversation!
    var regularGroupConversation: ZMConversation!

    override func setUp() {
        super.setUp()

        meetingConversation = createGroupConversation(groupType: .meeting)
        regularGroupConversation = createGroupConversation(groupType: .group)

        XCTAssertTrue(uiMOC.saveOrRollback())
    }

    override func tearDown() {
        meetingConversation = nil
        regularGroupConversation = nil
        super.tearDown()
    }

    func testThatMeetingConversationIsExcludedFromConversationsIncludingArchived() {
        // given
        let sut = uiMOC.conversationListDirectory()

        // then
        XCTAssertFalse(sut.conversationsIncludingArchived.items.contains(meetingConversation))
        XCTAssertTrue(sut.conversationsIncludingArchived.items.contains(regularGroupConversation))
    }

    func testThatMeetingConversationIsExcludedFromUnarchivedConversations() {
        // given
        let sut = uiMOC.conversationListDirectory()

        // then
        XCTAssertFalse(sut.unarchivedConversations.items.contains(meetingConversation))
        XCTAssertTrue(sut.unarchivedConversations.items.contains(regularGroupConversation))
    }

    func testThatMeetingConversationIsExcludedFromGroupConversations() {
        // given
        let sut = uiMOC.conversationListDirectory()

        // then
        XCTAssertFalse(sut.groupConversations.items.contains(meetingConversation))
        XCTAssertTrue(sut.groupConversations.items.contains(regularGroupConversation))
    }

    // MARK: - Helper

    private func createGroupConversation(groupType: ConversationGroupType) -> ZMConversation {
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.lastServerTimeStamp = Date()
        conversation.lastReadServerTimeStamp = conversation.lastServerTimeStamp
        conversation.remoteIdentifier = .create()
        conversation.conversationType = .group
        conversation.groupType = groupType
        return conversation
    }
}
