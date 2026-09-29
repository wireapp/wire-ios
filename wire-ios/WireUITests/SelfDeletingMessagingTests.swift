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

import WireFoundation
import XCTest

/// [core-messenger]
final class SelfDeletingMessagingTests: WireUITestCase {

    private typealias ReturnedTeam = (
        teamOwner: UserInfo,
        teamMember: UserInfo,
        conversationId: UUID,
        conversationDomain: String
    )

    @MainActor
    private func registerGroupTeam() async throws -> ReturnedTeam {
        let groupName = UserGenerator.generateRandomConversationName()
        let (teamOwner, teamMembers, _, conversationID) = try await UserHelper.default.registerTeam(
            withMemberCount: 1,
            conversation: .group(groupName)
        )

        return (
            teamOwner,
            teamMembers[0],
            try XCTUnwrap(conversationID, "conversationId is nil"),
            UserHelper.default.backend.domainInfo
        )
    }

    @MainActor
    func testUserCanSendSelfDeletingMessageWhichExpiresAfterSetTimer_TC_11829() async throws {

        // GIVEN
        let originalTextMessage = UserGenerator.generateRandomMessage()
        let groupTeam = try await registerGroupTeam()

        let activeConversationPage = try app.loginUser(
            email: groupTeam.teamOwner.email,
            password: groupTeam.teamOwner.password
        )
        .acceptPopup()
        .openConversation()

        // WHEN - set a self-deleting timer for the next message, before sending it
        activeConversationPage.selectSelfDeletingMessageTimer("3 seconds")
        activeConversationPage.verifyEphemeralIndicatorShows("3 seconds")
        activeConversationPage.verifyInputFieldShowsSelfDeletingPlaceholder()
        try activeConversationPage.sendMessage(originalTextMessage)

        // THEN - message is sent, shows a live countdown, then expires (is obfuscated)
        activeConversationPage.verifyMessageSent(originalTextMessage)
        activeConversationPage.verifyEphemeralCountdownVisible()
        activeConversationPage.verifyMessageExpired()
    }

    @MainActor
    func testAllMessagesAreSelfDeletingAfterSettingGlobalTimerFromSettings_TC_11830() async throws {

        // GIVEN
        let originalTextMessage = UserGenerator.generateRandomMessage()
        let groupTeam = try await registerGroupTeam()

        var activeConversationPage = try app.loginUser(
            email: groupTeam.teamOwner.email,
            password: groupTeam.teamOwner.password
        )
        .acceptPopup()
        .openConversation()

        // WHEN - set a conversation-wide self-deleting timer from conversation settings
        activeConversationPage = try activeConversationPage.openConversationDetails()
            .openTimeoutOptions()
            .select(displayString: "3 seconds")
            .closeTimeoutOptions()

        // THEN - a system message confirms the new conversation-wide timer
        activeConversationPage.verifyMessageTimerSystemMessage("3 seconds")

        // AND - send a regular message, without touching the per-message timer
        try activeConversationPage.sendMessage(originalTextMessage)

        // THEN - message is sent, shows a live countdown, then expires (is obfuscated)
        activeConversationPage.verifyMessageSent(originalTextMessage)
        activeConversationPage.verifyEphemeralCountdownVisible()
        activeConversationPage.verifyMessageExpired()
    }
}
