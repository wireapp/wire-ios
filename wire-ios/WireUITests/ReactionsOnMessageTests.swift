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
final class ReactionsOnMessageTests: WireUITestCase {

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
    func testAddReactionToMessageInGroupConversation_TC_11827() async throws {

        // GIVEN
        let reactionEmoji = "❤️"
        let originalTextMessage = UserGenerator.generateRandomMessage()
        let groupTeam = try await registerGroupTeam()

        let activeConversationPage = try app.loginUser(
            email: groupTeam.teamOwner.email,
            password: groupTeam.teamOwner.password
        )
        .acceptPopup()
        .openConversation()

        try await testServicesClient.sendText(
            user: groupTeam.teamMember,
            text: originalTextMessage,
            conversationId: groupTeam.conversationId,
            domain: groupTeam.conversationDomain
        )

        let message = activeConversationPage.message(withText: originalTextMessage)

        // WHEN - react with emoji
        activeConversationPage.reactToMessage(message, withEmoji: reactionEmoji)

        // THEN
        XCTAssertTrue(
            activeConversationPage.reactionOnMessage(emoji: reactionEmoji).waitForExistence(timeout: 5),
            "Expected reaction \(reactionEmoji) was not shown on message"
        )

        // WHEN - tap reaction again to deselect it
        XCTAssertTrue(
            activeConversationPage.reactionOnMessage(emoji: reactionEmoji).waitAndTap(),
            "Reaction \(reactionEmoji) was not tappable"
        )

        // THEN - reaction removed
        XCTAssertTrue(
            activeConversationPage.reactionOnMessage(emoji: reactionEmoji).waitForNonExistence(timeout: 5),
            "Reaction \(reactionEmoji) should be removed after tapping it again"
        )
    }

    @MainActor
    func testNotAbleToAddReactionToPingOrSelfDeletingMessageInGroupConversation_TC_12130() async throws {

        // GIVEN
        let reactionEmoji = "❤️"
        let selfDeletingTextMessage = UserGenerator.generateRandomMessage()
        let groupTeam = try await registerGroupTeam()

        let activeConversationPage = try app.loginUser(
            email: groupTeam.teamOwner.email,
            password: groupTeam.teamOwner.password
        )
        .acceptPopup()
        .openConversation()

        try await testServicesClient.sendPing(
            user: groupTeam.teamMember,
            conversationId: groupTeam.conversationId,
            domain: groupTeam.conversationDomain
        )

        let pingMessage = activeConversationPage.receivedPing(for: groupTeam.teamMember.name)
        XCTAssertTrue(
            pingMessage.waitForExistence(timeout: 5),
            "Expected ping message was not found, possible that not being sent via testService"
        )

        // WHEN - long-press ping message
        pingMessage.press(forDuration: 1.0)

        // THEN - no reaction option offered
        XCTAssertFalse(
            activeConversationPage.reactionButton(emoji: reactionEmoji).waitForExistence(timeout: 2),
            "Reaction picker should not be offered for ping messages"
        )

        try await testServicesClient.sendText(
            user: groupTeam.teamMember,
            text: selfDeletingTextMessage,
            conversationId: groupTeam.conversationId,
            domain: groupTeam.conversationDomain,
            timeoutMillis: 60_000 // messageTimer => self-deleting message
        )

        let selfDeletingMessage = activeConversationPage.message(withText: selfDeletingTextMessage)
        XCTAssertTrue(
            selfDeletingMessage.waitForExistence(timeout: 5),
            "Expected self-deleting message was not found, possible that not being sent via testService"
        )

        // WHEN - long-press self-deleting message
        selfDeletingMessage.press(forDuration: 1.0)

        // THEN - no reaction option offered
        XCTAssertFalse(
            activeConversationPage.reactionButton(emoji: reactionEmoji).waitForExistence(timeout: 2),
            "Reaction picker should not be shown for self-deleting messages"
        )
    }

    @MainActor
    func testEditingMessageRemovesReaction_TC_11828() async throws {

        // GIVEN
        let reactionEmoji = "❤️"
        let originalTextMessage = UserGenerator.generateRandomMessage()
        let editedTextMessage = "\(originalTextMessage)-Edited"
        let groupTeam = try await registerGroupTeam()

        let activeConversationPage = try app.loginUser(
            email: groupTeam.teamOwner.email,
            password: groupTeam.teamOwner.password
        )
        .acceptPopup()
        .openConversation()

        let originalMessageId = try await testServicesClient.sendText(
            user: groupTeam.teamMember,
            text: originalTextMessage,
            conversationId: groupTeam.conversationId,
            domain: groupTeam.conversationDomain,
            returnMessageId: true
        )

        let message = activeConversationPage.message(withText: originalTextMessage)

        // WHEN - logged-in user reacts to the message
        activeConversationPage.reactToMessage(message, withEmoji: reactionEmoji)

        // THEN
        XCTAssertTrue(
            activeConversationPage.reactionOnMessage(emoji: reactionEmoji).waitForExistence(timeout: 5),
            "Expected reaction \(reactionEmoji) was not shown on message"
        )

        // WHEN - sender edits the message
        try await testServicesClient.updateText(
            user: groupTeam.teamMember,
            originalMessageId: originalMessageId,
            newText: editedTextMessage,
            conversationId: groupTeam.conversationId,
            domain: groupTeam.conversationDomain
        )

        // THEN - edited message is shown and reaction is removed
        XCTAssertTrue(
            activeConversationPage.message(withText: editedTextMessage).waitForExistence(timeout: 5),
            "Expected edited message was not found"
        )
        XCTAssertTrue(
            activeConversationPage.reactionOnMessage(emoji: reactionEmoji).waitForNonExistence(timeout: 5),
            "Reaction still shown after the message is edited"
        )
    }
}
