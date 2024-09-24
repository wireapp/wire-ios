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

import WireDataModelSupport
@testable import WireRequestStrategy
import WireRequestStrategySupport

final class MessageInfoExtractorTests: XCTestCase {

    var sut: MessageInfoExtractor!
    var coreDataStack: CoreDataStack!
    var modelHelper: ModelHelper!
    var mockProteusMessage: MockProteusMessage!

    override func setUpWithError() throws {
        try super.setUpWithError()
        DeveloperFlag.proteusViaCoreCrypto.enable(true, storage: .temporary())
        
        coreDataStack = CoreDataStack(account: .init(userName: "F", userIdentifier: .create()),
                                      applicationContainer: URL(fileURLWithPath: "/dev/null"),
                                      inMemoryStore: true)

        coreDataStack.loadStores { _ in

        }
        sut = MessageInfoExtractor(context: coreDataStack.syncContext)
        modelHelper = ModelHelper()

        mockProteusMessage = MockProteusMessage()
        mockProteusMessage.context = coreDataStack.syncContext
        mockProteusMessage.underlyingMessage = Scaffolding.genericMessage
        mockProteusMessage.underlyingTargetRecipients = .conversationParticipants
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        sut = nil
        coreDataStack = nil
        modelHelper = nil
        mockProteusMessage = nil
    }

    var context: NSManagedObjectContext {
        coreDataStack.syncContext
    }

    func test_infoForSending_For2DifferentsUsersWithOneClient() async throws {
        // GIVEN
        let expectedListClients: MessageInfo.ClientList = [
            Scaffolding.userAID.domain: [
                Scaffolding.userAID.uuid: [
                    UserClientData(sessionID: .init(domain: Scaffolding.userAID.domain,
                                                    userID: Scaffolding.userAID.uuid.uuidString,
                                                    clientID: Scaffolding.clientAID))
                ]
            ]
        ]

        var conversation: ZMConversation!

        let conversationID = try await context.perform { [self] in
            _ = modelHelper.createSelfUser(id: Scaffolding.selfUserID.uuid,
                                               domain: Scaffolding.selfUserID.domain,
                                               in: context)
            let selfClient = modelHelper.createSelfClient(id: Scaffolding.selfClientID, in: context)

            let userA = modelHelper.createUser(qualifiedID: Scaffolding.userAID, in: context)
            _ = modelHelper.createClient(id: Scaffolding.clientAID, for: userA)

            conversation = ZMConversation.insertGroupConversation(moc: context, participants: [userA, selfClient.user!])
            conversation.remoteIdentifier = Scaffolding.conversationID.uuid
            conversation.domain = Scaffolding.conversationID.domain
            mockProteusMessage.conversation = conversation
            return try XCTUnwrap(conversation.qualifiedID)
        }

        // WHEN
        let messageInfo = try await sut.infoForSending(message: mockProteusMessage, conversationID: conversationID)

        // THEN
        XCTAssertEqual(messageInfo.genericMessage.messageID, Scaffolding.genericMessage.messageID)
        XCTAssertEqual(messageInfo.missingClientsStrategy, .doNotIgnoreAnyMissingClient)
        XCTAssertEqual(messageInfo.nativePush, true)
        XCTAssertEqual(messageInfo.selfClientID, Scaffolding.selfClientID)
        XCTAssertEqual(messageInfo.listClients, expectedListClients)
    }

    func test_infoForSending_ForSameUserWithTwoClients() async throws {
        // GIVEN
        let expectedListClients: MessageInfo.ClientList = [
            Scaffolding.selfUserID.domain: [
                Scaffolding.selfUserID.uuid: [
                    UserClientData(sessionID: .init(domain: Scaffolding.selfUserID.domain,
                                                    userID: Scaffolding.selfUserID.uuid.uuidString,
                                                    clientID: Scaffolding.selfOtherClientID))
                ]
            ]
        ]
        var conversation: ZMConversation!

        let conversationID = try await context.perform { [self] in
            let selfUser = modelHelper.createSelfUser(id: Scaffolding.selfUserID.uuid,
                                               domain: Scaffolding.selfUserID.domain,
                                               in: context)
            let selfClient = modelHelper.createSelfClient(id: Scaffolding.selfClientID, in: context)
            _ = modelHelper.createClient(id: Scaffolding.selfOtherClientID,
                                                           for: selfUser)

            conversation = ZMConversation.insertGroupConversation(moc: context, participants: [ selfClient.user!])
            conversation.remoteIdentifier = Scaffolding.conversationID.uuid
            conversation.domain = Scaffolding.conversationID.domain
            mockProteusMessage.conversation = conversation
            return try XCTUnwrap(conversation.qualifiedID)
        }

        // WHEN
        let messageInfo = try await sut.infoForSending(message: mockProteusMessage, conversationID: conversationID)

        // THEN
        XCTAssertEqual(messageInfo.genericMessage.messageID, Scaffolding.genericMessage.messageID)
        XCTAssertEqual(messageInfo.missingClientsStrategy, .doNotIgnoreAnyMissingClient)
        XCTAssertEqual(messageInfo.nativePush, true)
        XCTAssertEqual(messageInfo.selfClientID, Scaffolding.selfClientID)
        XCTAssertEqual(messageInfo.listClients, expectedListClients)
    }

    func test_infoForSending_WithUserNoSession() async throws {
        // GIVEN
        let expectedListClients = [
            Scaffolding.userAID.domain: [
                Scaffolding.userAID.uuid: [
                    UserClientData(sessionID: .init(domain: Scaffolding.userAID.domain,
                                                    userID: Scaffolding.userAID.uuid.uuidString,
                                                    clientID: Scaffolding.clientAID),
                    data: ZMFailedToCreateEncryptedMessagePayloadString.data(using: .utf8)!)
                ]
            ]
        ]

        var conversation: ZMConversation!

        let conversationID = try await context.perform { [self] in
            _ = modelHelper.createSelfUser(id: Scaffolding.selfUserID.uuid,
                                               domain: Scaffolding.selfUserID.domain,
                                               in: context)
            let selfClient = modelHelper.createSelfClient(id: Scaffolding.selfClientID, in: context)

            let userA = modelHelper.createUser(qualifiedID: Scaffolding.userAID, in: context)
            let clientA = modelHelper.createClient(id: Scaffolding.clientAID, for: userA)

            clientA.failedToEstablishSession = true // changed here

            conversation = ZMConversation.insertGroupConversation(moc: context, participants: [userA, selfClient.user!])
            conversation.remoteIdentifier = Scaffolding.conversationID.uuid
            conversation.domain = Scaffolding.conversationID.domain
            mockProteusMessage.conversation = conversation
            return try XCTUnwrap(conversation.qualifiedID)
        }

        // WHEN
        let messageInfo = try await sut.infoForSending(message: mockProteusMessage, conversationID: conversationID)

        // THEN
        XCTAssertEqual(messageInfo.genericMessage.messageID, Scaffolding.genericMessage.messageID)
        XCTAssertEqual(messageInfo.missingClientsStrategy, .doNotIgnoreAnyMissingClient)
        XCTAssertEqual(messageInfo.nativePush, true)
        XCTAssertEqual(messageInfo.selfClientID, Scaffolding.selfClientID)
        XCTAssertEqual(messageInfo.listClients, expectedListClients)
    }

    func test_infoForSending_WithUserDeletedAccount() async throws {
        // GIVEN
        let expectedListClients: MessageInfo.ClientList = [
            Scaffolding.userAID.domain: [
                Scaffolding.userAID.uuid: [
                    UserClientData(sessionID: .init(domain: Scaffolding.userAID.domain,
                                                    userID: Scaffolding.userAID.uuid.uuidString,
                                                    clientID: Scaffolding.clientAID))
                ]
                // no selfuser nor deletedUser
            ]
        ]

        var conversation: ZMConversation!

        let conversationID = try await context.perform { [self] in
            _ = modelHelper.createSelfUser(id: Scaffolding.selfUserID.uuid,
                                               domain: Scaffolding.selfUserID.domain,
                                               in: context)
            let selfClient = modelHelper.createSelfClient(id: Scaffolding.selfClientID, in: context)

            let userA = modelHelper.createUser(qualifiedID: Scaffolding.userAID, in: context)
            _ = modelHelper.createClient(id: Scaffolding.clientAID, for: userA)

            let deletedUser = modelHelper.createUser(in: context)
            _ = modelHelper.createClient(for: deletedUser)
            deletedUser.markAccountAsDeleted(at: .now) // changed here

            conversation = ZMConversation.insertGroupConversation(moc: context, participants: [userA, selfClient.user!, deletedUser])
            conversation.remoteIdentifier = Scaffolding.conversationID.uuid
            conversation.domain = Scaffolding.conversationID.domain
            mockProteusMessage.conversation = conversation
            return try XCTUnwrap(conversation.qualifiedID)
        }

        // WHEN
        let messageInfo = try await sut.infoForSending(message: mockProteusMessage, conversationID: conversationID)

        // THEN
        XCTAssertEqual(messageInfo.genericMessage.messageID, Scaffolding.genericMessage.messageID)
        XCTAssertEqual(messageInfo.missingClientsStrategy, .doNotIgnoreAnyMissingClient)
        XCTAssertEqual(messageInfo.nativePush, true)
        XCTAssertEqual(messageInfo.selfClientID, Scaffolding.selfClientID)
        XCTAssertEqual(messageInfo.listClients, expectedListClients)
    }

    private enum Scaffolding {
        static var selfUserID: QualifiedID = .randomID()
        static var selfClientID: String = .randomClientIdentifier()
        static var selfOtherClientID: String = .randomClientIdentifier()

        static var userAID: QualifiedID = .randomID()
        static var clientAID: String = .randomClientIdentifier()

        static var genericMessage: GenericMessage = .init()
        static var conversationID: QualifiedID = .randomID()
    }
}
