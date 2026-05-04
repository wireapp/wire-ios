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
import WireDataModel
import WireDataModelSupport
import WireNetworkSupport
import WireTestingPackage
import XCTest

@testable import WireDomain
@testable import WireDomainSupport
@testable import WireNetwork

final class ConversationEphemeralMessageNotificationBuilderTests: XCTestCase {
    private var sut: ConversationEphemeralMessageNotificationBuilder!
    private var conversationLocalStore: MockConversationLocalStoreProtocol!
    private var messageLocalStore: MockMessageLocalStoreProtocol!
    private var userLocalStore: MockUserLocalStoreProtocol!

    private var stack: CoreDataStack!
    private var coreDataStackHelper: CoreDataStackHelper!
    private var modelHelper: ModelHelper!

    private var context: NSManagedObjectContext {
        stack.syncContext
    }

    override func setUp() async throws {
        conversationLocalStore = MockConversationLocalStoreProtocol()
        userLocalStore = MockUserLocalStoreProtocol()
        messageLocalStore = MockMessageLocalStoreProtocol()
        modelHelper = ModelHelper()
        coreDataStackHelper = CoreDataStackHelper()
        stack = try await coreDataStackHelper.createStack()
    }

    override func tearDown() async throws {
        stack = nil
        sut = nil
        conversationLocalStore = nil
        messageLocalStore = nil
        userLocalStore = nil
        try coreDataStackHelper.cleanupDirectory()
        modelHelper = nil
        coreDataStackHelper = nil
    }

    func testGenerateEphemeralMessageNotification_With_Mention() async throws {

        // Mock

        let isMessageMentioningSelf = true
        let isMessageQuotingSelf = false

        await setupMock(
            isMessageMentioningSelf: isMessageMentioningSelf,
            isMessageQuotingSelf: isMessageQuotingSelf
        )

        sut = ConversationEphemeralMessageNotificationBuilder(
            context: .init(
                conversationLocalStore: conversationLocalStore,
                userLocalStore: userLocalStore,
                messageLocalStore: messageLocalStore
            )
        )

        var ephemeral = Ephemeral()
        var text = Text()
        text.content = "foo"
        ephemeral.text = text

        // When
        let userNotification = await sut.buildContent(
            ephemeral: ephemeral,
            conversationID: Scaffolding.conversationID,
            senderID: Scaffolding.userID
        )

        try await internalTest_assertNotificationContent(
            try XCTUnwrap(userNotification),
            isMention: isMessageMentioningSelf,
            isReply: isMessageQuotingSelf
        )
    }

    func testGenerateEphemeralMessageNotification_With_Reply() async throws {

        // Mock

        let isMessageMentioningSelf = false
        let isMessageQuotingSelf = true // reply

        await setupMock(
            isMessageMentioningSelf: isMessageMentioningSelf,
            isMessageQuotingSelf: isMessageQuotingSelf
        )

        sut = ConversationEphemeralMessageNotificationBuilder(
            context: .init(
                conversationLocalStore: conversationLocalStore,
                userLocalStore: userLocalStore,
                messageLocalStore: messageLocalStore
            )
        )

        var ephemeral = Ephemeral()
        var text = Text()
        text.content = "foo"
        ephemeral.text = text

        // When
        let userNotification = await sut.buildContent(
            ephemeral: ephemeral,
            conversationID: Scaffolding.conversationID,
            senderID: Scaffolding.userID
        )

        try await internalTest_assertNotificationContent(
            try XCTUnwrap(userNotification),
            isMention: isMessageMentioningSelf,
            isReply: isMessageQuotingSelf
        )
    }

    func testGenerateEphemeralMessageNotification() async throws {

        // Mock

        let isMessageMentioningSelf = false
        let isMessageQuotingSelf = false

        await setupMock(
            isMessageMentioningSelf: isMessageMentioningSelf,
            isMessageQuotingSelf: isMessageQuotingSelf
        )

        sut = ConversationEphemeralMessageNotificationBuilder(
            context: .init(
                conversationLocalStore: conversationLocalStore,
                userLocalStore: userLocalStore,
                messageLocalStore: messageLocalStore
            )
        )

        var ephemeral = Ephemeral()
        var text = Text()
        text.content = "foo"
        ephemeral.text = text

        // When
        let userNotification = await sut.buildContent(
            ephemeral: ephemeral,
            conversationID: Scaffolding.conversationID,
            senderID: Scaffolding.userID
        )

        try await internalTest_assertNotificationContent(
            try XCTUnwrap(userNotification),
            isMention: isMessageMentioningSelf,
            isReply: isMessageQuotingSelf
        )
    }

    private func internalTest_assertNotificationContent(
        _ userNotification: UserNotification,
        isMention: Bool,
        isReply: Bool
    ) async throws {

        guard case let .text(notificationContent) = userNotification else {
            return XCTFail()
        }

        // Body
        if isMention {
            XCTAssertEqual(notificationContent.body, "Someone mentioned you")
        } else if isReply {
            XCTAssertEqual(notificationContent.body, "Someone replied to you")
        } else {
            XCTAssertEqual(notificationContent.body, "Someone sent a message")
        }

        // Category
        XCTAssertEqual(
            notificationContent.categoryIdentifier,
            NotificationCategory.unmutedConversation.rawValue
        )

        XCTAssertEqual(notificationContent.sound, UNNotificationSound(named: .init("default")))

        // User info
        XCTAssertEqual(notificationContent.userInfo["selfUserIDString"] as! String, UUID.mockID1.uuidString)
        XCTAssertEqual(notificationContent.userInfo["senderIDString"] as! String, UUID.mockID3.uuidString)
        XCTAssertEqual(notificationContent.userInfo["conversationIDString"] as! String, UUID.mockID2.uuidString)

    }

    private func setupMock(
        isMessageMentioningSelf: Bool,
        isMessageQuotingSelf: Bool
    ) async {
        let conversation = await context.perform { [self] in
            modelHelper.createGroupConversation(in: context)
        }

        conversationLocalStore.fetchOrCreateConversationIdDomain_MockValue = conversation
        userLocalStore.fetchSelfUser_MockValue = await context.perform { [self] in
            modelHelper.createSelfUser(in: context)
        }
        userLocalStore.idFor_MockValue = .mockID1
        messageLocalStore.fetchMessageIdConversationIDConversationDomain_MockValue = await context.perform { [self] in
            ZMOTRMessage.fetch(withNonce: .mockID1, for: conversation, in: context)
        }
        messageLocalStore.isMessageMentioningSelfText_MockValue = isMessageMentioningSelf
        messageLocalStore.isMessageQuotingSelfQuotedMessage_MockValue = isMessageQuotingSelf
        conversationLocalStore.increaseUnreadCountFor_MockMethod = { _ in }
        conversationLocalStore.increaseUnreadSelfReplyCountFor_MockMethod = { _ in }
        conversationLocalStore.increaseUnreadSelfMentionCountFor_MockMethod = { _ in }
    }

    private enum Scaffolding {
        static let senderName = "User1"
        static let conversationName = "Conversation1"
        static let teamName = "Team1"
        static let conversationID = WireNetwork.QualifiedID(id: .mockID2, domain: "domain.com")
        static let userID = UserID(id: .mockID3, domain: "domain.com")
    }
}
