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
    private func loginToBackend(user: UserInfo) async throws -> (ConversationsPage) {

        let firstTimePage = try app.loginUser(email: user.email, password: user.password)

        return try firstTimePage
            .acceptPopup(with: self)
    }

    @MainActor
    func testClearContent() async throws {
        let stagingTeam = try await userHelper.registerTeam(withMemberCount: 2)
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

        var activeConversationPage = try conversationsPage
            .openConversation()
        var sentMessages = try XCTUnwrap(activeConversationPage.fetchMessages())
        XCTAssertTrue(sentMessages.isEmpty)

        // WHEN
        activeConversationPage = try activeConversationPage
            .sendMessage("another test")
            .openConversationDetails()
            .moreOptionsConversationDetails()
            .clearContentOptionsConversationDetails()
            .clearContent()
            .closeConversationDetails()

        sentMessages = try XCTUnwrap(activeConversationPage.fetchMessages())
        XCTAssertTrue(sentMessages.isEmpty, "got \(sentMessages.count) messages")
    }

}
