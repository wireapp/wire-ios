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

import Foundation
import WireMockTransport
import XCTest

class APNSTests_Swift: APNSTestsBase {
    func testThatItUpdatesApplicationBadgeCount_WhenReceivingATextMessage() {
        // GIVEN
        XCTAssertTrue(login())

        let textMessage = GenericMessage(content: Text(content: "Hello"), nonce: .create())

        closePushChannelAndWaitUntilClosed() // do not use websocket

        mockTransportSession.performRemoteChanges { session in
            guard
                let fromClient = self.user1.clients.anyObject() as? MockUserClient,
                let toClient = self.selfUser.clients.anyObject() as? MockUserClient,
                let data = try? textMessage.serializedData() else {
                return XCTFail()
            }
            // insert message on backend
            self.selfToUser1Conversation.encryptAndInsertData(from: fromClient, to: toClient, data: data)

            // register new client
            session.registerClient(for: self.user1)
        }
        _ = waitForAllGroupsToBeEmpty(withTimeout: 0.5)

        application?.setBackground()
        application?.simulateApplicationDidEnterBackground()
        _ = waitForAllGroupsToBeEmpty(withTimeout: 0.5)
        XCTAssertEqual(application?.applicationIconBadgeNumber, 0)

        // WHEN
        guard let userSession else {
            XCTFail("missing userSession")
            return
        }

        let exp = XCTestExpectation(description: "wait for receivedPushNotification to complete")
        userSession.receivedPushNotification(with: noticePayloadForLastEvent(), completion: {
            exp.fulfill()
        })
        wait(for: [exp], timeout: 5)

        // THEN
        XCTAssertEqual(application?.applicationIconBadgeNumber, 1)

        // CLEANUP
        application?.setActive()
        application?.simulateApplicationWillEnterForeground()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.2))
    }
}
