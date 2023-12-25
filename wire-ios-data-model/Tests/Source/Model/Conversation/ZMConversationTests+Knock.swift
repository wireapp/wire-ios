//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

final class ZMConversationTests_Knock: ZMConversationTestsBase {
    func testThatItCanInsertAKnock() {
        let context = syncMOC

        context.performGroupedBlockAndWait {

            // given
            let conversation = self.createConversationWithMessages(context: context)
            let selfUser = ZMUser.selfUser(in: context)

            // when
            let knock = try? conversation?.appendKnock()
            let msg = conversation?.lastMessage as! ZMMessage

            // then
            XCTAssertEqual(knock as? ZMMessage, msg)
            XCTAssertNotNil(knock?.knockMessageData)
            XCTAssert(knock!.isUserSender(selfUser))
        }

    }

    private func createConversationWithMessages(context: NSManagedObjectContext) -> ZMConversation? {
        let conversation = ZMConversation.insertNewObject(in: context)
        conversation.remoteIdentifier = NSUUID.create()
        for (index, text) in ["A", "B", "C", "D", "E"].enumerated() {
            let conversationMessage = try? conversation.appendText(content: text) as? ZMClientMessage
            conversationMessage?.updateServerTimestamp(with: TimeInterval(index))
        }
        XCTAssert(context.saveOrRollback())
        return conversation
    }
}
