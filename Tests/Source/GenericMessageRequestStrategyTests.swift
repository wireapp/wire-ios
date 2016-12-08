//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

@testable import WireMessageStrategy

class GenericMessageRequestStrategyTests : MessagingTest {
    
    let mockClientRegistrationStatus = MockClientRegistrationStatus()
    var conversation: ZMConversation!
    var sut : GenericMessageRequestStrategy!
    
    override func setUp() {
        super.setUp()
        
        sut = GenericMessageRequestStrategy(context: syncMOC, clientRegistrationDelegate: mockClientRegistrationStatus)
        
        createSelfClient()
        
        let user = ZMUser.insertNewObject(in: syncMOC)
        user.remoteIdentifier = UUID.create()
        _ = createClient(for: user, createSessionWithSelfUser: true)
        
        conversation = ZMConversation.insertNewObject(in: syncMOC)
        conversation.conversationType = .group
        conversation.remoteIdentifier = UUID.create()
        conversation.addParticipant(user)
    }
    
    func testThatItCreatesARequestForAGenericMessage() {
        
        // given
        let genericMessage = ZMGenericMessage(editMessage: "foo", newText: "bar", nonce: UUID.create().transportString())
        sut.schedule(message: genericMessage, inConversation: conversation) { ( _ ) in }
        
        // when
        let request = sut.nextRequest()
        
        // then
        XCTAssertEqual(request!.method, .methodPOST)
        XCTAssertEqual(request!.path, "/conversations/\(conversation.remoteIdentifier!.transportString())/otr/messages")
    }
    
}
