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

import SnapshotTesting
import XCTest
@testable import Wire

final class MessageActionsViewControllerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        let mockSelfUser = MockUserType.createSelfUser(name: "selfUser")
        SelfUser.provider = SelfProvider(selfUser: mockSelfUser)
    }

    func testContextMenuForTextMessage() {
        // GIVEN
        let message = MockMessageFactory.textMessage(withText: "Test tests")
        message.senderUser = MockUserType.createUser(name: "Bob")

        // WHEN
        let actionController = ConversationMessageActionController(responder: nil, message: message, context: .content, view: UIView())
        let sut = MessageActionsViewController.controller(withActions: MessageAction.allCases, actionController: actionController)

        // THEN
        verify(matching: sut)
    }

}
