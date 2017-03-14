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


@testable import WireMessageStrategy
import XCTest
import WireMessageStrategy
import ZMCDataModel
import ZMTransport

class GenericMessageNotificationRequestStrategyTests: MessagingTestBase {

    let mockClientRegistrationStatus = MockClientRegistrationStatus()
    var sut: GenericMessageNotificationRequestStrategy!

    override func setUp() {
        super.setUp()

        sut = GenericMessageNotificationRequestStrategy(managedObjectContext: syncMOC, clientRegistrationDelegate: mockClientRegistrationStatus)

    }

    func testThatItDoesNotCreateARequestWhenNoNotificationWasFired() {
        // WHEN & then
        XCTAssertNil(sut.nextRequest())
    }

    func testThatItCreatesARequestWhenPostingAGenericMessageScheduleNotification() {
        // GIVEN
        let genericMessage = ZMGenericMessage.sessionReset(withNonce: UUID.create().transportString())
        let notification = GenericMessageScheduleNotification(message: genericMessage, conversation: self.groupConversation)

        // WHEN
        notification.post()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        guard let request = sut.nextRequest() else { return XCTFail("No request created") }
        XCTAssertEqual(request.method, .methodPOST)
        XCTAssertEqual(request.path, "/conversations/\(self.groupConversation.remoteIdentifier!.transportString())/otr/messages")
    }
    
}
