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

import CoreData
@testable import WireDataModel

final class ZMConversationTests_Knock: ZMConversationTestsBase {
    // MARK: Internal

    func testThatItCanInsertAKnock() throws {
        try context.performGroupedAndWait {
            // given
            let conversation = self.createConversationWithMessages(context: context)
            let selfUser = ZMUser.selfUser(in: context)

            // when
            let knock = try XCTUnwrap(conversation?.appendKnock() as? ZMMessage)
            let msg = try XCTUnwrap(conversation?.lastMessage as? ZMMessage)

            // then
            XCTAssertEqual(knock, msg)
            XCTAssertNotNil(knock.knockMessageData)
            XCTAssert(knock.isUserSender(selfUser))
        }
    }

    // MARK: Private

    private var context: NSManagedObjectContext { syncMOC }

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
