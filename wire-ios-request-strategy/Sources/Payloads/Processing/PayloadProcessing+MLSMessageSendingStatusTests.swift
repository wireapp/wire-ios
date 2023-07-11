// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

class PayloadProcessing_MLSMessageSendingStatusTests: MessagingTestBase {

    let domain = "example.com"

    override func setUp() {
        super.setUp()

        syncMOC.performGroupedBlockAndWait {
            self.otherUser.domain = self.domain
        }
    }

    func testThatItAddsFailedToSendRecipients() throws {
        try self.syncMOC.performGroupedAndWait { _ in
            // given
            guard let message = try self.groupConversation.appendText(content: "Test message") as? ZMClientMessage else {
                XCTFail("Failed to add message")
                return
            }

            XCTAssertEqual(message.failedToSendRecipients?.count, 0)

            // When
            let qualifiedID = try XCTUnwrap(self.otherUser.qualifiedID)
            let failedToSendUsers = [qualifiedID]
            let payload = Payload.MLSMessageSendingStatus(time: Date(),
                                                          events: [Data()],
                                                          failedToSend: failedToSendUsers)
            payload.updateFailedRecipients(for: message)

            // Then
            XCTAssertEqual(message.failedToSendRecipients?.count, 1)
            XCTAssertEqual(message.failedToSendRecipients?.first, self.otherUser)
        }
    }

}
