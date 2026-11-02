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

    override func additionalDeveloperFlags() -> [DeveloperFlag: Bool] {
        [.offlinePendingMessages: true]
    }

    @MainActor
    func testSendOfflineMessagesInOneOnOneConversationAfterReconnection_TC_12191() async throws {
        let notificationName = "com.wire.ios.uitests.transport.offline.\(UUID().uuidString)"
        var token: Int32 = NOTIFY_TOKEN_INVALID
        XCTAssertEqual(notify_register_check(notificationName, &token), UInt32(NOTIFY_STATUS_OK))
        defer { notify_cancel(token) }
        XCTAssertEqual(notify_set_state(token, 0), UInt32(NOTIFY_STATUS_OK))

        app.terminate()
        app.launchEnvironment["UITEST_TRANSPORT_OFFLINE_NOTIFICATION"] = notificationName
        app.launch()

        let (recipient, members, _, _) = try await UserHelper.default.registerTeam(withMemberCount: 1)
        let sender = try XCTUnwrap(members.first)
        _ = try app.loginUser(email: recipient.email, password: recipient.password)
            .acceptPopup()
            .openUserProfilePage()
            .tapAddAccountOrTeamButton()
        let page = try app.loginUser(email: sender.email, password: sender.password)
            .acceptPopup()
            .tapPlusButtonToCreateGroup()
            .openUserDetailsInContactList()
            .tapStartConversationButton()
        let (conversationID, domain) = try await UserHelper.default
            .getConversationId(matching: .conversationType(.oneOnOne))
        let conversationDomain = try XCTUnwrap(domain)

        // Confirm the recipient is connected and receives messages before going offline.
        _ = try await testServicesClient.getInstanceId(
            email: recipient.email,
            password: recipient.password,
            name: recipient.name,
            verificationCode: nil
        )
        let onlineMessage = "Online \(UUID().uuidString.prefix(8))"
        try page.sendMessage(onlineMessage)
        let onlineTexts = try await waitForReceivedTexts(
            [onlineMessage], user: recipient, conversationID: conversationID, domain: conversationDomain
        )
        XCTAssertTrue(onlineTexts.contains(onlineMessage), "Recipient must be online before testing the offline queue")
        XCTAssertTrue(page.message(withText: onlineMessage).waitForExistence(timeout: 5))
        XCTAssertFalse(page.offlineNotices.firstMatch.exists)

        // Hold the sender's transport while the independent recipient remains online.
        XCTAssertEqual(notify_set_state(token, 1), UInt32(NOTIFY_STATUS_OK))
        XCTAssertEqual(notify_post(notificationName), UInt32(NOTIFY_STATUS_OK))
        defer {
            notify_set_state(token, 0)
            notify_post(notificationName)
        }
        let notice = page.offlineNotices.firstMatch
        XCTAssertTrue(notice.waitForExistence(timeout: 10))
        XCTAssertEqual(
            page.offlineNoticeText.label,
            "You are offline. Your messages will be sent once you are online again."
        )

        let queuedMessages = ["First offline message", "Second offline message"]
        for message in queuedMessages {
            try page.sendMessage(message)
            XCTAssertTrue(page.message(withText: message).waitForExistence(timeout: 5))
        }
        XCTAssertEqual(page.offlineNotices.count, 1, "Only one offline notice should appear for the queued messages")
        XCTAssertTrue(page.sendingIndicators.firstMatch.waitForExistence(timeout: 5))
        XCTAssertLessThanOrEqual(page.message(withText: onlineMessage).frame.maxY, notice.frame.minY)
        XCTAssertLessThanOrEqual(notice.frame.maxY, page.message(withText: queuedMessages[0]).frame.minY)

        let clock = ContinuousClock()
        let offlineDeadline = clock.now.advanced(by: .seconds(5))
        repeat {
            let texts = try await testServicesClient.receivedTexts(
                user: recipient, conversationId: conversationID, domain: conversationDomain
            )
            XCTAssertTrue(
                texts.allSatisfy { !queuedMessages.contains($0) },
                "The recipient must not receive queued messages while the sender is offline"
            )
            try await Task.sleep(for: .milliseconds(500))
        } while clock.now < offlineDeadline

        // Resume the same app session: queued messages must send without a manual retry.
        XCTAssertEqual(notify_set_state(token, 0), UInt32(NOTIFY_STATUS_OK))
        XCTAssertEqual(notify_post(notificationName), UInt32(NOTIFY_STATUS_OK))
        XCTAssertTrue(notice.waitForNonExistence(timeout: 10))
        let receivedTexts = try await waitForReceivedTexts(
            queuedMessages, user: recipient, conversationID: conversationID, domain: conversationDomain
        )
        for message in queuedMessages {
            XCTAssertEqual(receivedTexts.filter { $0 == message }.count, 1, "Expected exactly one copy of \(message)")
            XCTAssertTrue(page.message(withText: message).exists)
        }
        XCTAssertTrue(page.sendingIndicators.firstMatch.waitForNonExistence(timeout: 10))

        let recipientPage = try page.goBackToConversationPage()
            .openUserProfilePage()
            .switchUserAccountForUser(withName: recipient.name)
            .openConversation()
        for message in queuedMessages {
            recipientPage.verifyMessageSent(message)
        }
        XCTAssertFalse(recipientPage.offlineNotices.firstMatch.exists)
        XCTAssertFalse(recipientPage.sendingIndicators.firstMatch.exists)
    }

    private func waitForReceivedTexts(
        _ expected: [String],
        user: UserInfo,
        conversationID: UUID,
        domain: String
    ) async throws -> [String] {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: .seconds(30))
        var texts: [String]
        repeat {
            texts = try await testServicesClient.receivedTexts(
                user: user, conversationId: conversationID, domain: domain
            )
            if expected.allSatisfy(texts.contains) {
                return texts
            }
            try await Task.sleep(for: .milliseconds(500))
        } while clock.now < deadline
        return texts
    }
}
