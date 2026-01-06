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
import WireDomainSupport
import WireTestingPackage
import XCTest

@testable import WireDomain

final class MessageLocalStoreTests: XCTestCase {

    private var sut: MessageLocalStore!
    private var stack: CoreDataStack!
    private var coreDataStackHelper: CoreDataStackHelper!
    private var modelHelper: ModelHelper!

    private var context: NSManagedObjectContext {
        stack.syncContext
    }

    override func setUp() async throws {
        coreDataStackHelper = CoreDataStackHelper()
        modelHelper = ModelHelper()
        stack = try await coreDataStackHelper.createStack()

        sut = MessageLocalStore(
            context: context
        )
    }

    override func tearDown() async throws {
        sut = nil
        stack = nil
        try coreDataStackHelper.cleanupDirectory()
        coreDataStackHelper = nil
        modelHelper = nil
    }

    // MARK: - Tests

    func testAddTextMessage_It_Adds_Message_To_Conversation() async throws {
        // Mock

        let (clientMessage, groupConversation, _, _) = await context.perform { [self] in
            let conversation = modelHelper.createGroupConversation(
                in: context
            )

            conversation.isForcedReadOnly = false

            let selfUser = modelHelper.createSelfUser(
                id: .mockID1,
                domain: nil,
                in: context
            )

            let user = modelHelper.createUser(in: context)

            let clientMessage = ZMClientMessage(context: context)

            return (clientMessage, conversation, selfUser, user)
        }

        // Given a regular message to add to a conversation
        let genericMessage = try XCTUnwrap(GenericMessage(from: Scaffolding.base64EncodedString, validate: true))

        // When

        await sut.addClientMessage(
            clientMessage,
            isNewMessage: true,
            genericMessage: genericMessage,
            conversation: groupConversation,
            senderID: .mockID1,
            senderDomain: Scaffolding.domain
        )

        // Then

        let expectedMessageText = "Everything"

        await internalTest_assertConversationLastMessage(
            expectedMessageText: expectedMessageText,
            conversation: groupConversation
        )
    }

    private func internalTest_assertConversationLastMessage(
        expectedMessageText: String,
        conversation: ZMConversation
    ) async {
        await context.perform {
            XCTAssertEqual(
                conversation.lastMessage?.textMessageData?.messageText,
                expectedMessageText
            )
        }
    }

    func testAddMessageToConversation_It_Adds_Correct_Message_To_Conversation() async {
        // Mock

        let user = await context.perform { [self] in
            modelHelper.createSelfUser(in: context)
            return modelHelper.createUser(id: Scaffolding.userID, in: context)
        }

        let conversation = await makeConversation(
            id: Scaffolding.conversationID,
            domain: Scaffolding.domain,
            creator: user
        )

        for messageType in Scaffolding.allSystemMessageTypes {
            await context.perform {
                conversation.removeAllMessages(conversation.allMessages)
            }

            // When

            await sut.addSystemMessage(
                messageType: messageType,
                conversationID: Scaffolding.conversationID,
                conversationDomain: Scaffolding.domain1
            )

            // Then

            await internalTest_assertConversationLastSystemMessages(
                messageType: messageType,
                conversation: conversation
            )
        }
    }

    private func internalTest_assertConversationLastSystemMessages(
        messageType: SystemMessageType,
        conversation: ZMConversation
    ) async {
        let lastMessagesTypes = await context.perform {
            conversation.allMessages
                .compactMap { $0 as? ZMSystemMessage }
                .map(\.systemMessageType)
                .sorted(by: { $0.rawValue < $1.rawValue })
        }

        let expectedResults = expectedResults(given: messageType)

        XCTAssertEqual(lastMessagesTypes.count, expectedResults.messagesCount)
        XCTAssertEqual(lastMessagesTypes, expectedResults.zmMessages)

    }

    private func makeConversation(
        id: UUID,
        domain: String?,
        creator: ZMUser
    ) async -> ZMConversation {
        await context.perform { [self] in
            let conversation = modelHelper.createGroupConversation(
                id: Scaffolding.conversationID,
                domain: Scaffolding.domain1,
                in: context
            )
            conversation.creator = creator
            conversation.hasReadReceiptsEnabled = true

            return conversation
        }
    }

    private func expectedResults(
        given messageType: SystemMessageType
    ) -> (messagesCount: Int, zmMessages: [ZMSystemMessageType]) {
        switch messageType {
        case .federationTermination:
            (messagesCount: 1, [.domainsStoppedFederating])
        case .participantsRemovedAnonymously:
            (messagesCount: 1, [.participantsRemoved])
        case .mlsMigrationMLSNotSupportedForSelfUser:
            (messagesCount: 1, [.mlsNotSupportedSelfUser])
        case .mlsMigrationMLSNotSupportedForOtherUser:
            (messagesCount: 1, [.mlsNotSupportedOtherUser])
        case .teamMemberRemoved:
            (messagesCount: 1, [.teamMemberLeave])
        case .participantsRemoved:
            (messagesCount: 1, [.participantsRemoved])
        case .newConversationCreated:
            (messagesCount: 2, [.newConversation, .readReceiptsOn])
        case .mlsMigrationStarted:
            (messagesCount: 1, [.mlsMigrationStarted])
        case .mlsMigrationPotentialGap:
            (messagesCount: 1, [.mlsMigrationPotentialGap])
        case .mlsMigrationFinalized:
            (messagesCount: 1, [.mlsMigrationFinalized])
        case .receiptModeIsOn:
            (messagesCount: 1, [.readReceiptsOn])
        case .messageTimerUpdate:
            (messagesCount: 1, [.messageTimerUpdate])
        case .participantsAdded:
            (messagesCount: 1, [.participantsAdded])
        case .conversationNameChanged:
            (messagesCount: 1, [.conversationNameChanged])
        case let .readReceiptsStatus(isEnabled, _, _):
            (messagesCount: 1, [isEnabled ? .readReceiptsEnabled : .readReceiptsDisabled])
        case .unknownMessageContentTypeReceived:
            (messagesCount: 1, [.unknownMessageContentTypeReceived])
        case .invalid:
            (messagesCount: 1, [.invalid])
        case .decryptionFailed:
            (messagesCount: 1, [.decryptionFailed_RemoteIdentityChanged])
        case .sessionReset:
            (messagesCount: 1, [.sessionReset])
        case .channelHistoryDepthModified:
            (messagesCount: 1, [.channelHistoryDepthModified])
        }
    }

    enum Scaffolding {
        static let conversationID = UUID()
        static let userID = UUID()
        static let otherUserID = UUID()
        static let domain1 = "domain1.com"
        static let domain2 = "domain2.com"
        static let date = Date.now
        static let base64EncodedString = "CiQ5ZTU2NTQwOS0xODZiLTRlN2YtYTE4NC05NzE4MGE0MDAwMDQSDAoKRXZlcnl0aGluZw=="
        static let domain = "domain.com"
        static let senderClientID = UUID()

        static let allSystemMessageTypes: [SystemMessageType] = [
            .federationTermination(domains: [domain1, domain2], date: date),
            .mlsMigrationFinalized(sender: (id: userID, domain: domain1), date: date),
            .mlsMigrationMLSNotSupportedForOtherUser(otherUser: (id: userID, domain: domain1)),
            .mlsMigrationMLSNotSupportedForSelfUser,
            .mlsMigrationPotentialGap(sender: (id: userID, domain: domain1), date: date),
            .mlsMigrationStarted(sender: (id: userID, domain: domain1), date: date),
            .teamMemberRemoved(member: (id: userID, domain: domain1), date: date),
            .receiptModeIsOn(date: date),
            .newConversationCreated(date: date),
            .participantsRemoved(
                participants: [(id: userID, domain: domain1)],
                sender: (id: userID, domain: domain1),
                date: date
            ),
            .participantsRemovedAnonymously(participants: [(id: userID, domain: domain1)], date: date),
            .invalid(sender: (id: userID, domain: domain1), date: date),
            .decryptionFailed(
                sender: (id: userID, domain: domain1),
                senderClientID: otherUserID.uuidString,
                remoteIdentityChanged: true,
                date: date
            ),
            .sessionReset(sender: (id: userID, domain: domain), senderClientID: otherUserID.uuidString, date: date),
            .participantsAdded(
                participants: [(id: userID, domain: domain1)],
                sender: (id: userID, domain: domain1),
                date: date
            ),
            .conversationNameChanged(newName: "newName", sender: (userID, domain1), date: date),
            .readReceiptsStatus(isEnabled: Bool.random(), sender: (userID, domain1), date: date),
            .channelHistoryDepthModified(sender: .init(id: userID, domain: domain1))
        ]
    }

}
