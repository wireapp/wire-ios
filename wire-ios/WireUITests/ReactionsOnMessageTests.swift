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

        // WHEN - react with first emoji
        activeConversationPage.reactToMessage(message, withEmoji: "👍")

        // THEN
        XCTAssertTrue(
            activeConversationPage.reactionIndicator(emoji: "👍").waitForExistence(timeout: 5),
            "Expected reaction 👍 was not shown on message"
        )

        // WHEN - react with second emoji
        activeConversationPage.reactToMessage(message, withEmoji: "❤️")

        // THEN
        XCTAssertTrue(
            activeConversationPage.reactionIndicator(emoji: "❤️").waitForExistence(timeout: 5),
            "Expected reaction ❤️ was not shown on message"
        )

        // WHEN - tap 👍 again to deselect it
        activeConversationPage.reactToMessage(message, withEmoji: "👍")

        // THEN - 👍 reaction removed, ❤️ still present
        XCTAssertFalse(
            activeConversationPage.reactionIndicator(emoji: "👍").waitForExistence(timeout: 2),
            "Reaction 👍 should be removed after tapping it again"
        )
        XCTAssertTrue(
            activeConversationPage.reactionIndicator(emoji: "❤️").exists,
            "Reaction ❤️ should still be present after deselecting 👍"
        )
    }

    @MainActor
    func testNotAbleToAddReactionToPingOrSelfDeletingMessageInGroupConversation_TC_12130() async throws {

        // GIVEN
        let originalTextMessage = UserGenerator.generateRandomMessage()
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
            activeConversationPage.reactionIndicator(emoji: "❤️").waitForExistence(timeout: 2),
            "Reaction option should not be available for ping messages"
        )
        XCTAssertFalse(
            app.buttons["❤️"].firstMatch.waitForExistence(timeout: 2),
            "Reaction picker should not be offered for ping messages"
        )

        try await testServicesClient.sendText(
            user: groupTeam.teamMember,
            text: originalTextMessage,
            conversationId: groupTeam.conversationId,
            domain: groupTeam.conversationDomain,
            timeoutMillis: 60_000 // messageTimer => self-deleting message
        )

        let selfDeletingMessage = activeConversationPage.message(withText: originalTextMessage)
        XCTAssertTrue(
            selfDeletingMessage.waitForExistence(timeout: 5),
            "Expected self-deleting message was not found, possible that not being sent via testService"
        )

        // WHEN - long-press self-deleting message
        selfDeletingMessage.press(forDuration: 1.0)

        // THEN - no reaction option offered
        XCTAssertFalse(
            app.buttons["❤️"].firstMatch.waitForExistence(timeout: 2),
            "Reaction picker should not be offered for self-deleting messages"
        )
    }
}
