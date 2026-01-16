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

import WireDataModel
import WireDataModelSupport
import WireNetworkSupport
import WireTestingPackage
import XCTest
@testable import WireDomain
@testable import WireDomainSupport
@testable import WireNetwork

final class ConversationMessageAddEventNotificationBuilderTests: XCTestCase {
    private var sut: ConversationMessageAddEventNotificationBuilder!
    private var conversationLocalStore: MockConversationLocalStoreProtocol!
    private var messageLocalStore: MockMessageLocalStoreProtocol!
    private var userLocalStore: MockUserLocalStoreProtocol!
    private var conversationTextNotificationBuilder: MockConversationTextMessageNotificationBuilderProtocol!
    private var conversationCallingEventNotificationBuilder: MockConversationCallingEventNotificationBuilderProtocol!
    private var conversationAudioMessageNotificationBuilder: MockConversationAudioMessageNotificationBuilderProtocol!
    private var conversationEphemeralMessageNotificationBuilder: MockConversationEphemeralMessageNotificationBuilderProtocol!
    private var conversationFileUploadMessageNotificationBuilder: MockConversationFileUploadMessageNotificationBuilderProtocol!
    private var conversationHiddenMessageNotificationBuilder: MockConversationHiddenMessageNotificationBuilderProtocol!
    private var conversationImageMessageNotificationBuilder: MockConversationImageMessageNotificationBuilderProtocol!
    private var conversationLocationMessageNotificationBuilder: MockConversationLocationMessageNotificationBuilderProtocol!
    private var conversationPingMessageNotificationBuilder: MockConversationPingMessageNotificationBuilderProtocol!
    private var conversationVideoMessageNotificationBuilder: MockConversationVideoMessageNotificationBuilderProtocol!
    private var conversationTextMessageNotificationBuilder: MockConversationTextMessageNotificationBuilderProtocol!

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
        conversationTextNotificationBuilder = MockConversationTextMessageNotificationBuilderProtocol()
        conversationCallingEventNotificationBuilder = MockConversationCallingEventNotificationBuilderProtocol()
        conversationAudioMessageNotificationBuilder = MockConversationAudioMessageNotificationBuilderProtocol()
        conversationEphemeralMessageNotificationBuilder = MockConversationEphemeralMessageNotificationBuilderProtocol()
        conversationFileUploadMessageNotificationBuilder =
            MockConversationFileUploadMessageNotificationBuilderProtocol()
        conversationHiddenMessageNotificationBuilder = MockConversationHiddenMessageNotificationBuilderProtocol()
        conversationImageMessageNotificationBuilder = MockConversationImageMessageNotificationBuilderProtocol()
        conversationLocationMessageNotificationBuilder = MockConversationLocationMessageNotificationBuilderProtocol()
        conversationPingMessageNotificationBuilder = MockConversationPingMessageNotificationBuilderProtocol()
        conversationVideoMessageNotificationBuilder = MockConversationVideoMessageNotificationBuilderProtocol()
        conversationTextMessageNotificationBuilder = MockConversationTextMessageNotificationBuilderProtocol()

        sut = ConversationMessageAddEventNotificationBuilder(
            context: .init(conversationLocalStore: conversationLocalStore),
            validator: .init(conversationLocalStore: conversationLocalStore),
            conversationCallingEventNotificationBuilder: conversationCallingEventNotificationBuilder,
            conversationAudioMessageNotificationBuilder: conversationAudioMessageNotificationBuilder,
            conversationEphemeralMessageNotificationBuilder: conversationEphemeralMessageNotificationBuilder,
            conversationFileUploadMessageNotificationBuilder: conversationFileUploadMessageNotificationBuilder,
            conversationHiddenMessageNotificationBuilder: conversationHiddenMessageNotificationBuilder,
            conversationImageMessageNotificationBuilder: conversationImageMessageNotificationBuilder,
            conversationLocationMessageNotificationBuilder: conversationLocationMessageNotificationBuilder,
            conversationPingMessageNotificationBuilder: conversationPingMessageNotificationBuilder,
            conversationVideoMessageNotificationBuilder: conversationVideoMessageNotificationBuilder,
            conversationTextMessageNotificationBuilder: conversationTextNotificationBuilder
        )
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
        conversationTextNotificationBuilder = nil
    }

    func testGenerateNotification_MLS_Text_Message_Content_It_Invokes_Text_Notification_Builder() async throws {

        // Mock
        let conversation = await context.perform { [self] in
            modelHelper.createGroupConversation(in: context)
        }
        conversationCallingEventNotificationBuilder.buildContentCallingAtConversationIDSenderID_MockValue = .some(nil)
        conversationTextNotificationBuilder
            .buildContentTextConversationIDSenderID_MockValue = .text(UNMutableNotificationContent())
        conversationLocalStore.fetchOrCreateConversationIdDomain_MockValue = conversation
        conversationLocalStore.isMessageSilencedSenderIDConversation_MockValue = false
        conversationLocalStore.shouldHideNotification_MockValue = false

        // When

        _ = try await sut.buildContent(
            event: .left(Scaffolding.mlsTextMessageEvent)
        )

        // Then
        XCTAssertEqual(conversationTextNotificationBuilder.buildContentTextConversationIDSenderID_Invocations.count, 1)
    }

    func testGenerateNotification_Proteus_Text_Message_Content_It_Invokes_Text_Notification_Builder() async throws {

        // Mock
        let conversation = await context.perform { [self] in
            modelHelper.createGroupConversation(in: context)
        }
        conversationCallingEventNotificationBuilder.buildContentCallingAtConversationIDSenderID_MockValue = .some(nil)
        conversationTextNotificationBuilder
            .buildContentTextConversationIDSenderID_MockValue = .text(UNMutableNotificationContent())
        conversationLocalStore.fetchOrCreateConversationIdDomain_MockValue = conversation
        conversationLocalStore.isMessageSilencedSenderIDConversation_MockValue = false
        conversationLocalStore.shouldHideNotification_MockValue = false

        // When

        _ = try await sut.buildContent(
            event: .right(Scaffolding.proteusTextMessageEvent)
        )

        // Then
        XCTAssertEqual(conversationTextNotificationBuilder.buildContentTextConversationIDSenderID_Invocations.count, 1)
    }

    // TODO: [WPB-17284] Add UTs (if possible) for other message content types

    private enum Scaffolding {
        static let conversationID = WireNetwork.QualifiedID(id: .mockID2, domain: "domain.com")
        static let userID = UserID(id: .mockID3, domain: "domain.com")
        static let mlsTextMessageEvent = ConversationMLSMessageAddEvent(
            conversationID: conversationID,
            senderID: userID,
            subconversation: "",
            message: messageContent,
            timestamp: .now,
            decryptedMessages: [.init(
                message: Scaffolding.base64EncodedString, // text content
                senderClientID: UUID.mockID1.uuidString
            )]
        )

        static let proteusTextMessageEvent = ConversationProteusMessageAddEvent(
            conversationID: conversationID,
            senderID: userID,
            timestamp: .now,
            message: MessageContent(encryptedMessage: "", decryptedMessage: base64EncodedString), // text content
            externalData: nil,
            messageSenderClientID: UUID.mockID1.uuidString,
            messageRecipientClientID: UUID.mockID2.uuidString
        )

        static let messageContent = "foo"
        static let base64EncodedString = "CiQ5ZTU2NTQwOS0xODZiLTRlN2YtYTE4NC05NzE4MGE0MDAwMDQSDAoKRXZlcnl0aGluZw=="
    }
}
