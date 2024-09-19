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
    
    func test_infoForTransport() async throws {
        // GIVEN
        let modelHelper = ModelHelper()
        var conversation: ZMConversation!
        
        let conversationID = try await context.perform { [self] in
            let selfUser = modelHelper.createSelfUser(in: context)
            let selfUser = ZMUser.selfUser(in: context)
            selfUser.remoteIdentifier = Scaffolding.selfUserAID.uuid
            selfUser.domain = Scaffolding.selfUserAID.domain
            
            
            
//            ZMUser.boxSelfUser(selfUser, inContextUserInfo: context)
            
            let selfClient = modelHelper.createClient(id: Scaffolding.selfClientID, for: selfUser)
            
            
            let userA = modelHelper.createUser(qualifiedID: Scaffolding.selfUserAID, in: context)
            modelHelper.createClient(for: userA)
            
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
        XCTAssertEqual(messageInfo.genericMessage, Scaffolding.genericMessage)
//        XCTAssertEqual(messageInfo.missingClientsStrategy, .ignoreAllMissingClientsNotFromUsers(userIds: Set<<#Element: Hashable#>>()))
        XCTAssertEqual(messageInfo.nativePush, false)
        XCTAssertEqual(messageInfo.selfClientID, Scaffolding.selfClientID)
//        XCTAssertEqual(messageInfo.listClients)
    }
    
    private enum Scaffolding {
        static var selfClientID: String = .randomClientIdentifier()
        static var selfUserAID: QualifiedID = .randomID()
        static var genericMessage: GenericMessage = .init()
        static var conversationID: QualifiedID = .randomID()
    }
}
