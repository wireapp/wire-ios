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
@testable import WireDataModel

final class ClientMessageTests_Cleared: BaseZMClientMessageTests {

    func testThatItCreatesPayloadForZMClearedMessages() async {
        var message: ZMClientMessage?

        await self.syncMOC.perform {
            self.syncConversation.clearedTimeStamp = Date()
            self.syncConversation.remoteIdentifier = UUID()
            message = try? ZMConversation.updateSelfConversation(withClearedOf: self.syncConversation)

        }

        // given
        guard let message else { return XCTFail("missing message") }
        // when
        guard let payloadAndStrategy = await message.encryptForTransport() else { return XCTFail("encryptForTransport failed") }

        // then
        switch payloadAndStrategy.strategy {
        case .doNotIgnoreAnyMissingClient:
            break
        default:
            XCTFail()
        }
    }

    func testThatLastClearedUpdatesInSelfConversationDontExpire() {

        self.syncMOC.performGroupedAndWait {
            // given
            self.syncConversation.remoteIdentifier = UUID()
            self.syncConversation.clearedTimeStamp = Date()

            // when
            guard let message = try? ZMConversation.updateSelfConversation(withClearedOf: self.syncConversation) else {
                XCTFail()
                return
            }

            // then
            XCTAssertNil(message.expirationDate)
        }
    }

    func testThatClearingMessageHistoryDeletesAllMessages() {

        self.syncMOC.performGroupedAndWait {

            self.syncConversation.remoteIdentifier = UUID()
            let message1 = try! self.syncConversation.appendText(content: "B") as! ZMMessage
            message1.expire(withReason: .unknown)

            try! self.syncConversation.appendText(content: "A")

            let message3 = try! self.syncConversation.appendText(content: "B") as! ZMMessage
            message3.expire(withReason: .unknown)

            self.syncConversation.lastServerTimeStamp = message3.serverTimestamp

            // when
            self.syncConversation.clearedTimeStamp = self.syncConversation.lastServerTimeStamp
            self.syncMOC.processPendingChanges()
            // then
            for message in self.syncConversation.allMessages {
                XCTAssertTrue(message.isDeleted)
            }
        }
    }
}
