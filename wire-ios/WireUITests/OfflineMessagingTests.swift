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

import notify
import WireUtilities
import XCTest

/// [core-messenger]
final class OfflineMessagingTests: WireUITestCase {

    private struct Fixture {
        let page: ActiveConversationPage
        let sender: UserInfo
        let recipients: [UserInfo]
        let conversationID: UUID
        let domain: String
        let conversationName: String
        let otherConversationName: String?
        let onlineMessage = "Online"
    }

    private var notificationName = ""
    private var offlineToken: Int32 = NOTIFY_TOKEN_INVALID

    override func additionalDeveloperFlags() -> [DeveloperFlag: Bool] {
        [.offlinePendingMessages: true]
    }

    @MainActor
    func testSendOfflineMessagesInOneOnOneConversationAfterReconnection_TC_12191() async throws {
        try await assertQueuedDelivery(in: makeFixture())
    }

    @MainActor
    func testSendOfflineMessagesInGroupAfterReconnection_TC_12192() async throws {
        try await assertQueuedDelivery(in: makeFixture(group: true))
    }

    @MainActor
    func testPendingMessagesSurviveVisitingAnotherConversation_TC_12193() async throws {
        let fixture = try await makeFixture(group: true, otherConversation: true)
        goOffline(in: fixture)
        let texts = ["First pending", "Second pending"]
        try queue(texts, on: fixture.page)

        let otherName = try XCTUnwrap(fixture.otherConversationName)
        let otherPage = try fixture.page.goBackToConversationPage().openConversation(named: otherName)
        XCTAssertTrue(otherPage.conversationTitle(named: otherName).exists)
        for text in texts {
            XCTAssertFalse(otherPage.message(withText: text).exists)
        }
        let returnedPage = try otherPage.goBackToConversationPage()
            .openConversation(named: fixture.conversationName)
        assertPending(texts, on: returnedPage)
        try await assertNotReceived(texts, in: fixture)
        try await reconnectAndAssertDelivery(texts, in: fixture)
    }

    @MainActor
    func testPendingMessagesAreSeparatedFromDeliveredMessages_TC_12194() async throws {
        let fixture = try await makeFixture()
        XCTAssertTrue(fixture.page.deliveredIndicators.firstMatch.waitForExistence(timeout: 5))
        goOffline(in: fixture)
        let texts = ["First pending", "Second pending"]
        try queue(texts, on: fixture.page)
        assertPending(texts, on: fixture.page)
        XCTAssertTrue(fixture.page.deliveredIndicators.firstMatch.exists)
        let notice = fixture.page.offlineNotices.firstMatch
        XCTAssertLessThanOrEqual(fixture.page.message(withText: fixture.onlineMessage).frame.maxY, notice.frame.minY)
        for text in texts {
            XCTAssertLessThanOrEqual(notice.frame.maxY, fixture.page.message(withText: text).frame.minY)
        }
        try await assertNotReceived(texts, in: fixture)
        try await reconnectAndAssertDelivery(texts, in: fixture)
    }

    @MainActor
    func testEditPendingOneOnOneMessagesTwiceWithoutEditedIndicator_TC_12195() async throws {
        try await assertRepeatedEdits(in: makeFixture())
    }

    @MainActor
    func testEditPendingGroupMessagesTwiceWithoutEditedIndicator_TC_12196() async throws {
        try await assertRepeatedEdits(in: makeFixture(group: true))
    }

    @MainActor
    func testCancelEditingPendingMessagePreservesOriginal_TC_12197() async throws {
        let fixture = try await makeFixture()
        goOffline(in: fixture)
        let original = "Original pending"
        try queue([original], on: fixture.page)
        for draft in ["Canceled first edit", "Canceled second edit"] {
            try fixture.page.beginEditingMessage(original)
            fixture.page.replaceEditingText(with: draft)
            fixture.page.cancelMessageEdit()
            XCTAssertTrue(fixture.page.message(withText: original).waitForExistence(timeout: 5))
            XCTAssertFalse(fixture.page.message(withText: draft).exists)
        }
        assertPending([original], on: fixture.page)
        try await assertNotReceived([original], in: fixture)
        try await reconnectAndAssertDelivery(
            [original], excluding: ["Canceled first edit", "Canceled second edit"], in: fixture
        )
    }

    @MainActor
    func testEditingSecondPendingMessageLeavesFirstAndThirdUnchanged_TC_12198() async throws {
        let fixture = try await makeFixture()
        goOffline(in: fixture)
        let original = ["First pending", "Second pending", "Third pending"]
        try queue(original, on: fixture.page)
        var second = original[1]
        for replacement in ["Second revised", "Second final"] {
            try fixture.page.editMessage(second, to: replacement)
            second = replacement
            XCTAssertTrue(fixture.page.message(withText: original[0]).exists)
            XCTAssertTrue(fixture.page.message(withText: original[2]).exists)
        }
        let expected = [original[0], second, original[2]]
        assertPending(expected, on: fixture.page)
        try await assertNotReceived(original + ["Second revised", second], in: fixture)
        try await reconnectAndAssertDelivery(expected, excluding: [original[1], "Second revised"], in: fixture)
    }

    @MainActor
    func testDeletePendingMessagesPreventsDeliveryAfterReconnection_TC_12199() async throws {
        let fixture = try await makeFixture()
        goOffline(in: fixture)
        let deleted = ["Delete first", "Delete second"]
        try queue(deleted, on: fixture.page)
        for text in deleted {
            try fixture.page.deletePendingMessage(text)
        }
        XCTAssertTrue(fixture.page.sendingIndicators.firstMatch.waitForNonExistence(timeout: 5))
        XCTAssertEqual(fixture.page.offlineNotices.count, 1)
        try await assertNotReceived(deleted, in: fixture)

        setOffline(false)
        XCTAssertTrue(fixture.page.offlineNotices.firstMatch.waitForNonExistence(timeout: 10))
        // A delivered message proves the transport resumed before checking the deleted texts.
        let barrier = "After deletion"
        try fixture.page.sendMessage(barrier)
        try await assertReceived([barrier], excluding: deleted, in: fixture)
        try await assertNotReceived(deleted, in: fixture)
        let recipientPage = try openRecipientConversation(in: fixture)
        XCTAssertTrue(recipientPage.message(withText: barrier).waitForExistence(timeout: 10))
        for text in deleted {
            XCTAssertFalse(recipientPage.message(withText: text).exists)
        }
    }

    // MARK: - Fixture

    @MainActor
    private func makeFixture(group: Bool = false, otherConversation: Bool = false) async throws -> Fixture {
        notificationName = "com.wire.ios.uitests.transport.offline.\(UUID().uuidString)"
        XCTAssertEqual(notify_register_check(notificationName, &offlineToken), UInt32(NOTIFY_STATUS_OK))
        let token = offlineToken
        let name = notificationName
        addTeardownBlock {
            notify_set_state(token, 0)
            notify_post(name)
            notify_cancel(token)
        }
        XCTAssertEqual(notify_set_state(token, 0), UInt32(NOTIFY_STATUS_OK))
        app.terminate()
        app.launchEnvironment["UITEST_TRANSPORT_OFFLINE_NOTIFICATION"] = notificationName
        app.launch()

        let groupName = UserGenerator.generateRandomConversationName()
        let (owner, members, memberIDs, groupID) = try await UserHelper.default.registerTeam(
            withMemberCount: group ? 2 : 1,
            conversation: group ? .group(groupName) : nil
        )
        let sender = try (group ? owner : XCTUnwrap(members.first))
        let recipients = group ? members : [owner]
        let recipient = try XCTUnwrap(recipients.first)
        let otherName = otherConversation ? UserGenerator.generateRandomConversationName() : nil
        if let otherName {
            _ = try await UserHelper.default.createGroupConversations(
                qualifiedIds: memberIDs, owner: owner, groupName: otherName
            )
        }

        _ = try app.loginUser(email: recipient.email, password: recipient.password)
            .acceptPopup().openUserProfilePage().tapAddAccountOrTeamButton()
        let conversations = try app.loginUser(email: sender.email, password: sender.password).acceptPopup()
        let page: ActiveConversationPage
        let conversationID: UUID
        let domain: String
        if group {
            if let otherName {
                _ = try conversations.openConversation(named: otherName).goBackToConversationPage()
            }
            page = try conversations.openConversation(named: groupName)
            conversationID = try XCTUnwrap(groupID)
            domain = UserHelper.default.backend.domainInfo
        } else {
            page = try conversations.tapPlusButtonToCreateGroup().openUserDetailsInContactList()
                .tapStartConversationButton()
            let conversation = try await UserHelper.default.getConversationId(matching: .conversationType(.oneOnOne))
            conversationID = conversation.conversationID
            domain = try XCTUnwrap(conversation.domain)
        }
        let fixture = Fixture(
            page: page, sender: sender, recipients: recipients, conversationID: conversationID, domain: domain,
            conversationName: group ? groupName : recipient.name, otherConversationName: otherName
        )
        for recipient in recipients {
            _ = try await testServicesClient.getInstanceId(
                email: recipient.email, password: recipient.password, name: recipient.name, verificationCode: nil
            )
        }
        try page.sendMessage(fixture.onlineMessage)
        try await assertReceived([fixture.onlineMessage], in: fixture)
        XCTAssertTrue(page.message(withText: fixture.onlineMessage).waitForExistence(timeout: 5))
        XCTAssertFalse(page.offlineNotices.firstMatch.exists)
        return fixture
    }

    // MARK: - Offline state and message assertions

    private func setOffline(_ offline: Bool) {
        XCTAssertEqual(notify_set_state(offlineToken, offline ? 1 : 0), UInt32(NOTIFY_STATUS_OK))
        XCTAssertEqual(notify_post(notificationName), UInt32(NOTIFY_STATUS_OK))
    }

    private func goOffline(in fixture: Fixture) {
        setOffline(true)
        XCTAssertTrue(fixture.page.offlineNotices.firstMatch.waitForExistence(timeout: 10))
        XCTAssertEqual(
            fixture.page.offlineNoticeText.label,
            "You are offline. Your messages will be sent once you are online again."
        )
    }

    private func queue(_ texts: [String], on page: ActiveConversationPage) throws {
        for text in texts {
            try page.sendMessage(text)
            XCTAssertTrue(page.message(withText: text).waitForExistence(timeout: 5))
        }
    }

    private func assertPending(_ texts: [String], on page: ActiveConversationPage) {
        XCTAssertEqual(page.offlineNotices.count, 1)
        XCTAssertTrue(page.sendingIndicators.firstMatch.waitForExistence(timeout: 5))
        for text in texts {
            XCTAssertTrue(page.message(withText: text).exists)
        }
    }

    @MainActor
    private func assertQueuedDelivery(in fixture: Fixture) async throws {
        goOffline(in: fixture)
        let texts = ["First pending", "Second pending"]
        try queue(texts, on: fixture.page)
        assertPending(texts, on: fixture.page)
        let notice = fixture.page.offlineNotices.firstMatch
        XCTAssertLessThanOrEqual(fixture.page.message(withText: fixture.onlineMessage).frame.maxY, notice.frame.minY)
        XCTAssertLessThanOrEqual(notice.frame.maxY, fixture.page.message(withText: texts[0]).frame.minY)
        try await assertNotReceived(texts, in: fixture)
        try await reconnectAndAssertDelivery(texts, in: fixture)
    }

    @MainActor
    private func assertRepeatedEdits(in fixture: Fixture) async throws {
        goOffline(in: fixture)
        let original = ["First pending", "Second pending"]
        let revised = ["First revised", "Second revised"]
        let final = ["First final", "Second final"]
        try queue(original, on: fixture.page)
        for index in original.indices {
            try fixture.page.editMessage(original[index], to: revised[index])
            try fixture.page.editMessage(revised[index], to: final[index])
            XCTAssertFalse(fixture.page.message(withText: original[index]).exists)
            XCTAssertFalse(fixture.page.message(withText: revised[index]).exists)
        }
        assertPending(final, on: fixture.page)
        XCTAssertFalse(fixture.page.editedIndicators.firstMatch.exists)
        try await assertNotReceived(original + revised + final, in: fixture)
        try await reconnectAndAssertDelivery(final, excluding: original + revised, in: fixture)
    }

    @MainActor
    private func reconnectAndAssertDelivery(
        _ texts: [String], excluding absent: [String] = [], in fixture: Fixture
    ) async throws {
        setOffline(false)
        XCTAssertTrue(fixture.page.offlineNotices.firstMatch.waitForNonExistence(timeout: 10))
        try await assertReceived(texts, excluding: absent, in: fixture)
        XCTAssertTrue(fixture.page.sendingIndicators.firstMatch.waitForNonExistence(timeout: 10))
        let recipientPage = try openRecipientConversation(in: fixture)
        for text in texts {
            XCTAssertTrue(recipientPage.message(withText: text).waitForExistence(timeout: 10))
        }
        for text in absent {
            XCTAssertFalse(recipientPage.message(withText: text).exists)
        }
        XCTAssertFalse(recipientPage.offlineNotices.firstMatch.exists)
        XCTAssertFalse(recipientPage.sendingIndicators.firstMatch.exists)
        XCTAssertFalse(recipientPage.editedIndicators.firstMatch.exists)
    }

    private func openRecipientConversation(in fixture: Fixture) throws -> ActiveConversationPage {
        let recipient = try XCTUnwrap(fixture.recipients.first)
        let name = fixture.conversationName == recipient.name ? fixture.sender.name : fixture.conversationName
        return try fixture.page.goBackToConversationPage().openUserProfilePage()
            .switchUserAccountForUser(withName: recipient.name)
            .openConversation(named: name)
    }

    private func assertReceived(
        _ expected: [String],
        excluding absent: [String] = [],
        in fixture: Fixture
    ) async throws {
        for recipient in fixture.recipients {
            let clock = ContinuousClock()
            let deadline = clock.now.advanced(by: .seconds(30))
            var texts: [String]
            repeat {
                texts = try await testServicesClient.receivedTexts(
                    user: recipient, conversationId: fixture.conversationID, domain: fixture.domain
                )
                try XCTUnwrap(app.state == .runningForeground ? true : nil, "Wire exited while waiting for delivery")
                if expected.allSatisfy(texts.contains) {
                    break
                }
                try await Task.sleep(for: .milliseconds(500))
            } while clock.now < deadline
            for text in expected {
                XCTAssertEqual(
                    texts.filter { $0 == text }.count,
                    1,
                    "Expected exactly one copy for \(recipient.name): \(text). Received: \(texts)"
                )
            }
            for text in absent {
                XCTAssertFalse(texts.contains(text), "Unexpected text received by \(recipient.name): \(text)")
            }
        }
    }

    private func assertNotReceived(_ absent: [String], in fixture: Fixture) async throws {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: .seconds(5))
        repeat {
            for recipient in fixture.recipients {
                let texts = try await testServicesClient.receivedTexts(
                    user: recipient, conversationId: fixture.conversationID, domain: fixture.domain
                )
                XCTAssertTrue(texts.allSatisfy { !absent.contains($0) }, "Queued text reached \(recipient.name)")
            }
            try await Task.sleep(for: .milliseconds(500))
        } while clock.now < deadline
    }
}
