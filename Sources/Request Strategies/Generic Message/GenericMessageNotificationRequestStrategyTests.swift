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


@testable import WireRequestStrategy
import XCTest
import WireRequestStrategy
import WireDataModel
import WireTransport

class GenericMessageNotificationRequestStrategyTests: MessagingTestBase {

    let mockClientRegistrationStatus = MockClientRegistrationStatus()
    var sut: GenericMessageNotificationRequestStrategy!

    override func setUp() {
        super.setUp()

        self.syncMOC.performGroupedAndWait { moc in
            self.sut = GenericMessageNotificationRequestStrategy(managedObjectContext: moc, clientRegistrationDelegate: self.mockClientRegistrationStatus)
        }

    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testThatItDoesNotCreateARequestWhenNoNotificationWasFired() {
        self.syncMOC.performGroupedAndWait { _ in
            // WHEN & then
            XCTAssertNil(self.sut.nextRequest())
        }
    }

    func testThatItCreatesARequestWhenPostingAGenericMessageScheduleNotification() {
        self.syncMOC.performGroupedAndWait { moc in
            // GIVEN
            let genericMessage = GenericMessage(clientAction: .resetSession)

            // WHEN
            GenericMessageScheduleNotification.post(message: genericMessage, conversation: self.groupConversation)
        }
        self.syncMOC.performGroupedAndWait { syncMOC in
            // THEN
            guard let request = self.sut.nextRequest() else { XCTFail("No request created"); return }
            XCTAssertEqual(request.method, .methodPOST)
            XCTAssertEqual(request.path, "/conversations/\(self.groupConversation.remoteIdentifier!.transportString())/otr/messages")
        }
    }
    
}
