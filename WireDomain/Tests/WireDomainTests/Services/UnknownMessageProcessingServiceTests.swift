//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

import Foundation
import XCTest
import WireDataModel
import WireDomain
import WireNetwork
@testable import WireDomain

final class UnknownMessageProcessingServiceTests: XCTestCase {

    var contextProvider: MockContextProvider!
    var conversationLocalStore: MockConversationLocalStore!
    var protobufMessageProcessor: MockConversationProtobufMessageProcessor!
    var service: UnknownMessageProcessingService!

    override func setUp() {
        super.setUp()
        contextProvider = MockContextProvider()
        conversationLocalStore = MockConversationLocalStore()
        protobufMessageProcessor = MockConversationProtobufMessageProcessor()
        
        service = UnknownMessageProcessingService(
            contextProvider: contextProvider,
            conversationLocalStore: conversationLocalStore,
            protobufMessageProcessor: protobufMessageProcessor
        )
    }

    override func tearDown() {
        service = nil
        protobufMessageProcessor = nil
        conversationLocalStore = nil
        contextProvider = nil
        super.tearDown()
    }

    func testProcessStoredUnknownMessages_WithNoMessages() async throws {
        // Given
        contextProvider.mockUnknownMessages = []

        // When
        try await service.processStoredUnknownMessages()

        // Then
        XCTAssertEqual(protobufMessageProcessor.processProtobufMessageCallCount, 0)
    }

    func testProcessStoredUnknownMessages_WithProcessableMessage() async throws {
        // Given
        let mockConversation = MockZMConversation()
        let mockSender = MockZMUser()
        let mockUnknownMessage = MockUnknownMessage()
        mockUnknownMessage.payload = Data("test payload".utf8)
        mockUnknownMessage.conversation = mockConversation
        mockUnknownMessage.sender = mockSender
        mockUnknownMessage.eventTimestamp = Date()
        mockUnknownMessage.senderClientID = "client123"

        contextProvider.mockUnknownMessages = [mockUnknownMessage]
        contextProvider.mockGenericMessage = MockGenericMessage()

        // When
        try await service.processStoredUnknownMessages()

        // Then
        XCTAssertEqual(protobufMessageProcessor.processProtobufMessageCallCount, 1)
        XCTAssertTrue(mockUnknownMessage.wasDeleted)
    }

    func testProcessStoredUnknownMessages_WithUnprocessableMessage() async throws {
        // Given
        let mockUnknownMessage = MockUnknownMessage()
        mockUnknownMessage.payload = Data("invalid payload".utf8)
        mockUnknownMessage.conversation = MockZMConversation()
        mockUnknownMessage.sender = MockZMUser()
        mockUnknownMessage.eventTimestamp = Date()

        contextProvider.mockUnknownMessages = [mockUnknownMessage]
        contextProvider.mockGenericMessage = nil // Cannot decode

        // When
        try await service.processStoredUnknownMessages()

        // Then
        XCTAssertEqual(protobufMessageProcessor.processProtobufMessageCallCount, 0)
        XCTAssertFalse(mockUnknownMessage.wasDeleted) // Should not be deleted if unprocessable
    }

}

// MARK: - Mock Classes

class MockContextProvider: ContextProvider {
    var syncContext: NSManagedObjectContext {
        return MockNSManagedObjectContext()
    }
    
    var mockUnknownMessages: [MockUnknownMessage] = []
    
    func perform<T>(_ block: @escaping (NSManagedObjectContext) -> T) async -> T {
        let context = MockNSManagedObjectContext()
        context.mockUnknownMessages = mockUnknownMessages
        return block(context)
    }
}

class MockNSManagedObjectContext: NSManagedObjectContext {
    var mockUnknownMessages: [MockUnknownMessage] = []
    
    override func fetch<T>(_ request: NSFetchRequest<T>) throws -> [T] {
        if request.entityName == "UnknownMessage" {
            return mockUnknownMessages as! [T]
        }
        return []
    }
    
    override func delete(_ object: NSManagedObject) {
        if let unknownMessage = object as? MockUnknownMessage {
            unknownMessage.wasDeleted = true
        }
    }
}

class MockUnknownMessage: UnknownMessage {
    var wasDeleted = false
    
    override init(nonce: UUID, managedObjectContext: NSManagedObjectContext) {
        super.init(nonce: nonce, managedObjectContext: managedObjectContext)
    }
}

class MockZMConversation: ZMConversation {
    override var qualifiedID: QualifiedID? {
        return QualifiedID(uuid: UUID(), domain: "example.com")
    }
}

class MockZMUser: ZMUser {
    override var qualifiedID: QualifiedID? {
        return QualifiedID(uuid: UUID(), domain: "example.com")
    }
}

class MockGenericMessage: GenericMessage {
    override var content: GenericMessage.OneOf_Content? {
        return .text(Text(content: "test message"))
    }
}

class MockConversationLocalStore: ConversationLocalStoreProtocol {
    func updateSecurityLevelAfterReceivingMessage(conversation: ZMConversation, genericMessage: GenericMessage, date: Date) async {
        // Mock implementation
    }
    
    func addParticipantIfNeeded(participantID: UUID, participantDomain: String, in conversation: ZMConversation, date: Date) async {
        // Mock implementation
    }
    
    // Add other required methods as needed
    func fetchConversation(id: UUID, domain: String?) async -> ZMConversation? { return nil }
    func updateLastReadMessageTimestamp(_ lastRead: LastRead, in conversation: ZMConversation) async {}
    func updateClearedMessageTimestamp(_ cleared: Cleared, in conversation: ZMConversation) async {}
    func addParticipant(participantID: UUID, participantDomain: String?, in conversation: ZMConversation, date: Date) async {}
    func removeParticipant(participantID: UUID, participantDomain: String?, from conversation: ZMConversation, date: Date) async {}
    func updateConversationName(_ name: String, in conversation: ZMConversation, date: Date) async {}
    func updateConversationReceiptMode(_ receiptMode: ReceiptMode, in conversation: ZMConversation, date: Date) async {}
    func updateConversationAccessMode(_ accessMode: ConversationAccessMode, in conversation: ZMConversation, date: Date) async {}
    func updateConversationAccessRole(_ accessRole: ConversationAccessRole, in conversation: ZMConversation, date: Date) async {}
    func updateConversationMessageTimer(_ messageTimer: MessageTimer, in conversation: ZMConversation, date: Date) async {}
    func updateConversationGuestLink(_ guestLink: GuestLink, in conversation: ZMConversation, date: Date) async {}
    func updateConversationGuestLinkStatus(_ guestLinkStatus: GuestLinkStatus, in conversation: ZMConversation, date: Date) async {}
    func updateConversationMLSVerificationStatus(_ mlsVerificationStatus: MLSVerificationStatus, in conversation: ZMConversation, date: Date) async {}
    func updateConversationMLSGroupID(_ mlsGroupID: MLSGroupID, in conversation: ZMConversation, date: Date) async {}
    func updateConversationMLSEpoch(_ mlsEpoch: MLSEpoch, in conversation: ZMConversation, date: Date) async {}
    func updateConversationMLSCommitBundle(_ mlsCommitBundle: MLSCommitBundle, in conversation: ZMConversation, date: Date) async {}
    func updateConversationMLSProposalBundle(_ mlsProposalBundle: MLSProposalBundle, in conversation: ZMConversation, date: Date) async {}
    func updateConversationMLSWelcomeMessage(_ mlsWelcomeMessage: MLSWelcomeMessage, in conversation: ZMConversation, date: Date) async {}
    func updateConversationMLSGroupInfo(_ mlsGroupInfo: MLSGroupInfo, in conversation: ZMConversation, date: Date) async {}
    func updateConversationMLSGroupInfoCommitBundle(_ mlsGroupInfoCommitBundle: MLSGroupInfoCommitBundle, in conversation: ZMConversation, date: Date) async {}
    func updateConversationMLSGroupInfoProposalBundle(_ mlsGroupInfoProposalBundle: MLSGroupInfoProposalBundle, in conversation: ZMConversation, date: Date) async {}
    func updateConversationMLSGroupInfoWelcomeMessage(_ mlsGroupInfoWelcomeMessage: MLSGroupInfoWelcomeMessage, in conversation: ZMConversation, date: Date) async {}
    func updateConversationMLSGroupInfoGroupInfo(_ mlsGroupInfoGroupInfo: MLSGroupInfoGroupInfo, in conversation: ZMConversation, date: Date) async {}
    func updateConversationMLSGroupInfoGroupInfoCommitBundle(_ mlsGroupInfoGroupInfoCommitBundle: MLSGroupInfoGroupInfoCommitBundle, in conversation: ZMConversation, date: Date) async {}
    func updateConversationMLSGroupInfoGroupInfoProposalBundle(_ mlsGroupInfoGroupInfoProposalBundle: MLSGroupInfoGroupInfoProposalBundle, in conversation: ZMConversation, date: Date) async {}
    func updateConversationMLSGroupInfoGroupInfoWelcomeMessage(_ mlsGroupInfoGroupInfoWelcomeMessage: MLSGroupInfoGroupInfoWelcomeMessage, in conversation: ZMConversation, date: Date) async {}
    func updateConversationMLSGroupInfoGroupInfoGroupInfo(_ mlsGroupInfoGroupInfoGroupInfo: MLSGroupInfoGroupInfoGroupInfo, in conversation: ZMConversation, date: Date) async {}
    func updateConversationMLSGroupInfoGroupInfoGroupInfoCommitBundle(_ mlsGroupInfoGroupInfoGroupInfoCommitBundle: MLSGroupInfoGroupInfoGroupInfoCommitBundle, in conversation: ZMConversation, date: Date) async {}
    func updateConversationMLSGroupInfoGroupInfoGroupInfoProposalBundle(_ mlsGroupInfoGroupInfoGroupInfoProposalBundle: MLSGroupInfoGroupInfoGroupInfoProposalBundle, in conversation: ZMConversation, date: Date) async {}
    func updateConversationMLSGroupInfoGroupInfoGroupInfoWelcomeMessage(_ mlsGroupInfoGroupInfoGroupInfoWelcomeMessage: MLSGroupInfoGroupInfoGroupInfoWelcomeMessage, in conversation: ZMConversation, date: Date) async {}
    func updateConversationMLSGroupInfoGroupInfoGroupInfoGroupInfo(_ mlsGroupInfoGroupInfoGroupInfoGroupInfo: MLSGroupInfoGroupInfoGroupInfoGroupInfo, in conversation: ZMConversation, date: Date) async {}
    func updateConversationMLSGroupInfoGroupInfoGroupInfoGroupInfoCommitBundle(_ mlsGroupInfoGroupInfoGroupInfoGroupInfoCommitBundle: MLSGroupInfoGroupInfoGroupInfoGroupInfoCommitBundle, in conversation: ZMConversation, date: Date) async {}
    func updateConversationMLSGroupInfoGroupInfoGroupInfoGroupInfoProposalBundle(_ mlsGroupInfoGroupInfoGroupInfoGroupInfoProposalBundle: MLSGroupInfoGroupInfoGroupInfoGroupInfoProposalBundle, in conversation: ZMConversation, date: Date) async {}
    func updateConversationMLSGroupInfoGroupInfoGroupInfoGroupInfoWelcomeMessage(_ mlsGroupInfoGroupInfoGroupInfoGroupInfoWelcomeMessage: MLSGroupInfoGroupInfoGroupInfoGroupInfoWelcomeMessage, in conversation: ZMConversation, date: Date) async {}
}

class MockConversationProtobufMessageProcessor: ConversationProtobufMessageProcessorProtocol {
    var processProtobufMessageCallCount = 0
    
    func processProtobufMessage(
        _ genericMessage: GenericMessage,
        conversation: ZMConversation,
        conversationID: ConversationID,
        senderID: UserID,
        senderClientID: String?,
        date: Date,
        eventMessage: String
    ) async throws {
        processProtobufMessageCallCount += 1
    }
}
