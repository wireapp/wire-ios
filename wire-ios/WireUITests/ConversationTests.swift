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

import XCTest

final class ConversationTests: WireUITestCase {

    @MainActor
    func testClearContent_TC_9488() async throws {
        let stagingTeam = try await UserHelper.default.registerTeam(withMemberCount: 2)
        let userA = try XCTUnwrap(stagingTeam.teamMembers.first)
        let userB = try XCTUnwrap(stagingTeam.teamMembers.last)

        let conversationsPage = try await loginToBackend(user: userA)

        // WHEN
        try conversationsPage
            .tapPlusButtonToCreateGroup()
            .tapNewGroupButton()
            .enterGroupName("test")
            .tapMemberCells(withLabelPrefixes: [userB.name])
            .doneSelectingMembers()
            .sendMessage("test")
            .sendMessage("test2")
            .goBackToConversationPage()
            .longPressForMoreOptionOnConversation()
            .clearContent()

        // THEN
        XCTAssertTrue(conversationsPage.conversationCell.exists)

        let activeConversationPage = try conversationsPage
            .openConversation()
        let sentMessages = try XCTUnwrap(activeConversationPage.fetchMessages())
        XCTAssertTrue(sentMessages.isEmpty)
    }

    @MainActor
    func testLeaveGroup_TC_8862() async throws {
        // GIVEN
        let (_, members, _, _) = try await UserHelper.default.registerTeam(
            withMemberCount: 2,
            conversation: .group("Test")
        )
        let activeConversationPage = try app.loginUser(email: members[0].email, password: members[0].password)
            .acceptPopup()
            .openConversation()
            // WHEN
            .sendMessage("test")
            .openConversationDetails()
            .moreOptionsConversationDetails()
            .leaveOptionsConversationDetails()
            .leaveConversation()
            .closeConversationDetails()

        // THEN
        let userMessages = try XCTUnwrap(activeConversationPage.fetchMessages())
        XCTAssertEqual(userMessages.count, 1)

        XCTAssertTrue(activeConversationPage.userLeftSystemMessage.exists, "the system message is missing")
    }

    @MainActor
    func testLeaveAndClearGroup_TC_10525() async throws {
        // GIVEN
        let (_, members, _, _) = try await UserHelper.default.registerTeam(
            withMemberCount: 2,
            conversation: .group("Test")
        )
        let activeConversationPage = try app.loginUser(email: members[0].email, password: members[0].password)
            .acceptPopup()
            .openConversation()
            // WHEN
            .sendMessage("test")
            .openConversationDetails()
            .moreOptionsConversationDetails()
            .leaveOptionsConversationDetails()
            .leaveAndClearConversation()
            .closeConversationDetails()

        // THEN
        let userMessages = try XCTUnwrap(activeConversationPage.fetchMessages())
        XCTAssertEqual(userMessages.count, 0)

        XCTAssertFalse(activeConversationPage.userLeftSystemMessage.exists, "the system message has not been removed")
    }

}
