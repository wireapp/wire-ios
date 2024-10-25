//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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
import XCTest
import WireDomainSupport
@testable import WireDomain

final class MessageLocalStoreTests: XCTestCase {

    private var sut: MessageLocalStore!
    private var conversationLocalStore: MockConversationLocalStoreProtocol!
    private var stack: CoreDataStack!
    private var coreDataStackHelper: CoreDataStackHelper!
    private var modelHelper: ModelHelper!

    private var context: NSManagedObjectContext {
        stack.syncContext
    }

    override func setUp() async throws {
        conversationLocalStore = MockConversationLocalStoreProtocol()
        coreDataStackHelper = CoreDataStackHelper()
        modelHelper = ModelHelper()
        stack = try await coreDataStackHelper.createStack()
        
        sut = MessageLocalStore(
            context: context,
            conversationLocalStore: conversationLocalStore
        )
    }

    override func tearDown() async throws {
        sut = nil
        stack = nil
        conversationLocalStore = nil
        try coreDataStackHelper.cleanupDirectory()
        coreDataStackHelper = nil
        modelHelper = nil
    }

    // MARK: - Tests

    func testAddMessageToConversation_It_Adds_Correct_Message_To_Conversation() async {
        
        // Mock
        
        let conversation = await context.perform { [self] in
            let conversation = modelHelper.createGroupConversation(in: context)
            modelHelper.createUser(id: Scaffolding.userID, in: context)
            modelHelper.createUser(id: Scaffolding.otherUserID, in: context)
            
            return conversation
        }
        
        conversationLocalStore.fetchConversationWithDomain_MockValue = conversation
        
        await withTaskGroup(of: Void.self) { taskGroup in
            for messageType in Scaffolding.allMessageTypes {
                taskGroup.addTask { [self] in
                    // When
                    await sut.addSystemMessageToConversation(
                        messageType: messageType,
                        conversationID: UUID(),
                        conversationDomain: Scaffolding.domain1
                    )
                    
                    // Then
                    
                    await internalTest_assertConversationLastMessagesTypes(
                        assertedMessageType: messageType,
                        conversation: conversation
                    )
                }
            }
            
            await taskGroup.waitForAll()
        }

    }
    
    private func internalTest_assertConversationLastMessagesTypes(
        assertedMessageType: MessageType,
        conversation: ZMConversation
    ) async {
        
        let lastMessagesTypes = await context.perform {
            conversation.allMessages
                .compactMap { $0 as? ZMSystemMessage }
                .map(\.systemMessageType)
        }
        
        switch assertedMessageType {
        case .federationTermination:
           // XCTAssertEqual(lastMessagesTypes.count, 1)
            XCTAssertEqual(lastMessagesTypes.contains(.domainsStoppedFederating), true)
        case .participantsRemovedAnonymously:
            //XCTAssertEqual(lastMessagesTypes.count, 1)
            XCTAssertEqual(lastMessagesTypes.contains(.participantsRemoved), true)
        case .mlsMigrationMLSNotSupportedForSelfUser:
            //XCTAssertEqual(lastMessagesTypes.count, 1)
            XCTAssertEqual(lastMessagesTypes.contains(.mlsNotSupportedSelfUser), true)
        case .mlsMigrationMLSNotSupportedForOtherUser:
            //XCTAssertEqual(lastMessagesTypes.count, 1)
            XCTAssertEqual(lastMessagesTypes.contains(.mlsNotSupportedOtherUser), true)
        case .teamMemberRemoved:
            //XCTAssertEqual(lastMessagesTypes.count, 1)
            XCTAssertEqual(lastMessagesTypes.contains(.teamMemberLeave), true)
        case .participantRemoved:
            //XCTAssertEqual(lastMessagesTypes.count, 1)
            XCTAssertEqual(lastMessagesTypes.contains(.participantsRemoved), true)
        case .newConversationCreated:
            //XCTAssertEqual(lastMessagesTypes.count, 2)
            XCTAssertEqual(lastMessagesTypes.contains([.newConversation, .readReceiptsOn]), true)
        case .mlsMigrationStarted:
            //XCTAssertEqual(lastMessagesTypes.count, 1)
            XCTAssertEqual(lastMessagesTypes.contains(.mlsMigrationStarted), true)
        case .mlsMigrationPotentialGap:
            //XCTAssertEqual(lastMessagesTypes.count, 1)
            XCTAssertEqual(lastMessagesTypes.contains(.mlsMigrationPotentialGap), true)
        case .mlsMigrationFinalized:
            //XCTAssertEqual(lastMessagesTypes.count, 1)
            XCTAssertEqual(lastMessagesTypes.contains(.mlsMigrationFinalized), true)
        case .receiptModeIsOn:
            //XCTAssertEqual(lastMessagesTypes.count, 1)
            XCTAssertEqual(lastMessagesTypes.contains(.readReceiptsOn), true)
        }
        
    }


    private enum Scaffolding {
        static let userID = UUID()
        static let otherUserID = UUID()
        static let domain1 = "domain1.com"
        static let domain2 = "domain2.com"
        static let date = Date.now
        
        static let allMessageTypes: [MessageType] = [
            .federationTermination(domains: [domain1, domain2], date: date),
            .mlsMigrationFinalized(sender: (id: userID, domain: domain1), date: date),
            .mlsMigrationMLSNotSupportedForOtherUser(otherUser: (id: userID, domain: domain1)),
            .mlsMigrationMLSNotSupportedForSelfUser,
            .mlsMigrationPotentialGap(sender: (id: userID, domain: domain1), date: date),
            .mlsMigrationStarted(sender: (id: userID, domain: domain1), date: date),
            .newConversationCreated(date: date),
            .participantRemoved(participant: (id: userID, domain: domain1), sender: (id: otherUserID, domain: domain1), date: date),
            .participantsRemovedAnonymously(participants: [(id: userID, domain: domain1)], date: date),
            .receiptModeIsOn(date: date),
            .teamMemberRemoved(member: (id: userID, domain: domain1), date: date)
        ]
    }

}

