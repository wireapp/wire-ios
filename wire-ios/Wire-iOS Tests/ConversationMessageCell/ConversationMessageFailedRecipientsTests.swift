//
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
@testable import Wire

final class ConversationMessageFailedRecipientsTests: CoreDataSnapshotTestCase {

    func testFailedRecipientsCell_WithOneUser() {
        // GIVEN, WHEN
        let message = MockMessageFactory.textMessage(withText: "Hello")
        message.conversationLike = otherUserConversation
        message.failedToSendUsers = [otherUser]
        message.conversation?.domain = "anta.wire.link"


        // THEN
        verify(message: message, allWidths: false)
    }

    func testFailedRecipientsCell_WithTwoUsers() {
        // GIVEN, WHEN
        let message = MockMessageFactory.textMessage(withText: "Hello")
        message.conversationLike = otherUserConversation
        let serviceUser = createServiceUser()
        message.failedToSendUsers = [otherUser, serviceUser]
        message.conversation?.domain = "anta.wire.link"

        // THEN
        verify(message: message, allWidths: false)
    }

}
