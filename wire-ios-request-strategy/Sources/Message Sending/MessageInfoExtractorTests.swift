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

import XCTest

@testable import WireRequestStrategy
import WireRequestStrategySupport
import WireDataModelSupport

final class MessageInfoExtractorTests: XCTestCase {
    
    var sut: MessageInfoExtractor!
    var coreDataStack: CoreDataStack!
    
    override func setUpWithError() throws {
        DeveloperFlag.proteusViaCoreCrypto.enable(true, storage: .temporary())
        
        try super.setUpWithError()
        coreDataStack = CoreDataStack(account: .init(userName: "F", userIdentifier: .create()),
                                      applicationContainer: URL(fileURLWithPath: "/dev/null"),
                                      inMemoryStore: true)
        
        coreDataStack.loadStores { _ in

        }
        sut = MessageInfoExtractor(context: coreDataStack.syncContext)
    }
    
    var context: NSManagedObjectContext {
        coreDataStack.syncContext
    }
    
    func test_infoForTransport_For2DifferentsUsersWithOneClient() async throws {
        // GIVEN
        let modelHelper = ModelHelper()
        var conversation: ZMConversation!
        
        let conversationID = try await context.perform { [self] in
            let _ = modelHelper.createSelfUser(id: Scaffolding.selfUserID.uuid,
                                               domain: Scaffolding.selfUserID.domain,
                                               in: context)
            let selfClient = modelHelper.createSelfClient(id: Scaffolding.selfClientID, in: context)
            
            
            let userA = modelHelper.createUser(qualifiedID: Scaffolding.userAID, in: context)
            let _ = modelHelper.createClient(id: Scaffolding.clientAID, for: userA)
            
            conversation = ZMConversation.insertGroupConversation(moc: context, participants: [userA, selfClient.user!])
            conversation.remoteIdentifier = Scaffolding.conversationID.uuid
            conversation.domain = Scaffolding.conversationID.domain
            return try XCTUnwrap(conversation.qualifiedID)
        }
        
        let mockProteusMessage = MockProteusMessage()
        mockProteusMessage.conversation = conversation
        mockProteusMessage.context = context
        mockProteusMessage.underlyingMessage = Scaffolding.genericMessage
        
        // WHEN
        let messageInfo = try await sut.infoForTransport(message: mockProteusMessage, conversationID: conversationID)
        
        // THEN
        print(messageInfo.listClients)
        XCTAssertEqual(messageInfo.genericMessage, Scaffolding.genericMessage)
        XCTAssertEqual(messageInfo.missingClientsStrategy, .doNotIgnoreAnyMissingClient)
        XCTAssertEqual(messageInfo.nativePush, true)
        XCTAssertEqual(messageInfo.selfClientID, Scaffolding.selfClientID)
        XCTAssertEqual(messageInfo.listClients, Scaffolding.expectedListClients)
    }

    func test_infoForTransport_ForSameUserWithTwoClients() async throws {
        // GIVEN
        let modelHelper = ModelHelper()
        var conversation: ZMConversation!
        
        let conversationID = try await context.perform { [self] in
            let selfUser = modelHelper.createSelfUser(id: Scaffolding.selfUserID.uuid,
                                               domain: Scaffolding.selfUserID.domain,
                                               in: context)
            let selfClient = modelHelper.createSelfClient(id: Scaffolding.selfClientID, in: context)
            let _ = modelHelper.createClient(id: Scaffolding.selfOtherClientID,
                                                           for: selfUser)

            conversation = ZMConversation.insertGroupConversation(moc: context, participants: [ selfClient.user!])
            conversation.remoteIdentifier = Scaffolding.conversationID.uuid
            conversation.domain = Scaffolding.conversationID.domain
            return try XCTUnwrap(conversation.qualifiedID)
        }
        
        let mockProteusMessage = MockProteusMessage()
        mockProteusMessage.conversation = conversation
        mockProteusMessage.context = context
        mockProteusMessage.underlyingMessage = Scaffolding.genericMessage
        
        // WHEN
        let messageInfo = try await sut.infoForTransport(message: mockProteusMessage, conversationID: conversationID)
        
        // THEN
        XCTAssertEqual(messageInfo.genericMessage, Scaffolding.genericMessage)
        XCTAssertEqual(messageInfo.missingClientsStrategy, .doNotIgnoreAnyMissingClient)
        XCTAssertEqual(messageInfo.nativePush, true)
        XCTAssertEqual(messageInfo.selfClientID, Scaffolding.selfClientID)
        XCTAssertEqual(messageInfo.listClients, Scaffolding.expectedListClients2)
    }

    private enum Scaffolding {
        static var selfUserID: QualifiedID = .randomID()
        static var selfClientID: String = .randomClientIdentifier()
        static var selfOtherClientID: String = .randomClientIdentifier()

        static var userAID: QualifiedID = .randomID()
        static var clientAID: String = .randomClientIdentifier()
        
        static var genericMessage: GenericMessage = .init()
        static var conversationID: QualifiedID = .randomID()
        
        static var expectedListClients: MessageInfo.ClientList = {
            [
                Scaffolding.userAID.domain: [
                    Scaffolding.userAID.uuid : [
                        UserClientData(sessionID: .init(domain: Scaffolding.userAID.domain,
                                                        userID: Scaffolding.userAID.uuid.uuidString,
                                                        clientID: Scaffolding.clientAID))
                    ]
                ]
            ]
        }()
        
        static var expectedListClients2: MessageInfo.ClientList = {
            [
                Scaffolding.selfUserID.domain: [
                    Scaffolding.selfUserID.uuid : [
                        UserClientData(sessionID: .init(domain: Scaffolding.selfUserID.domain,
                                                        userID: Scaffolding.selfUserID.uuid.uuidString,
                                                        clientID: Scaffolding.selfOtherClientID))
                    ]
                ]
            ]
        }()
    }
}
