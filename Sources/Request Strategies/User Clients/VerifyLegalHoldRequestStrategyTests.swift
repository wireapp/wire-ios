// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

class VerifyLegalHoldRequestStrategyTests: MessagingTestBase {

    var sut: VerifyLegalHoldRequestStrategy!
    var mockApplicationStatus : MockApplicationStatus!
    
    override func setUp() {
        super.setUp()
        mockApplicationStatus = MockApplicationStatus()
        mockApplicationStatus.mockSynchronizationState = .eventProcessing
        sut = VerifyLegalHoldRequestStrategy(withManagedObjectContext: self.syncMOC, applicationStatus: mockApplicationStatus)
    }
    
    override func tearDown() {
        mockApplicationStatus = nil
        sut = nil
        super.tearDown()
    }
    
    
    // MARK: Fetching client based on needsToBeUpdatedFromBackend flag
    
    func testThatItCreatesARequest_WhenConversationNeedsToVerifyLegalHold() {
        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            let conversation = self.createGroupConversation(with: self.otherUser)
            
            // WHEN
            conversation.setValue(true, forKey: #keyPath(ZMConversation.needsToVerifyLegalHold))
            self.sut.objectsDidChange(Set(arrayLiteral: conversation))
            
            // THEN
            XCTAssertEqual(self.sut.nextRequest()?.path, "/conversations/\(conversation.remoteIdentifier!.transportString())/otr/messages")
        }
    }
    
    func testThatItResetsNeedsToVerifyLegalHoldFlag_WhenReceivingTheResponse() {
        var conversation: ZMConversation!
        syncMOC.performGroupedBlockAndWait {
            // GIVEN
            conversation = self.createGroupConversation(with: self.otherUser)
            conversation.setValue(true, forKey: #keyPath(ZMConversation.needsToVerifyLegalHold))
            self.sut.objectsDidChange(Set(arrayLiteral: conversation))
            let request = self.sut.nextRequest()
            
            // WHEN
            request?.complete(with: ZMTransportResponse(payload: [:] as ZMTransportData, httpStatus: 200, transportSessionError: nil))
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))

        // THEN
        syncMOC.performGroupedBlockAndWait {
            XCTAssertFalse(conversation.needsToVerifyLegalHold)
        }
    }

}
