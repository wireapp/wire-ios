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
    
    override func setUp() async throws {
        try await super.setUp()
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
        
        await context.perform { [self] in
            
            let selfClient = modelHelper.createSelfClient(id: Scaffolding.selfClientID, in: context)
            let userA = modelHelper.createUser(qualifiedID: Scaffolding.selfUserAID, in: context)
            modelHelper.createClient(for: userA)
            
            conversation = ZMConversation.insertGroupConversation(moc: context, participants: [userA, selfClient.user!])
            
        }
        
        let mockProteusMessage = MockProteusMessage()
        
        let id = try XCTUnwrap(conversation.qualifiedID)
        
        // WHEN
        let messageInfo = try await sut.infoForTransport(message: mockProteusMessage, conversationID: id)
        
        // THEN
        XCTAssertEqual(messageInfo.genericMessage, )
    }
    
    private enum Scaffolding {
        static var selfClientID: String = .randomClientIdentifier()
        static var selfUserAID: QualifiedID = .randomID()
    }
}
