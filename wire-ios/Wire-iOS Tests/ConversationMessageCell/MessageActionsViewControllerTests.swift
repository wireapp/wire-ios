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

    func testMenuActionsForTextMessage() {
        // GIVEN
        let message = MockMessageFactory.textMessage(withText: "Test tests")
        message.senderUser = MockUserType.createUser(name: "Bob")

        // WHEN
        let actionController = ConversationMessageActionController(responder: nil, message: message, context: .content, view: UIView())
        let sut = MessageActionsViewController.controller(withActions: MessageAction.allCases, actionController: actionController)

        // THEN
        let actionsTitles = sut.actions.map { $0.title ?? "" }
        XCTAssertArrayEqual(actionsTitles, ["Copy", "Reply", "Details", "Share", "Delete", "Cancel"])
    }
}

final class BasicReactionPickerTests: ZMSnapshotTestCase {

    func test_BasicReactionPicker() {
        // GIVEN WHEN
        let sut = pickerWithReaction(nil)

        // THEN
        verify(matching: sut)
    }

    func test_BasicReactionPicker_withSelectedReaction() {
        // GIVEN WHEN
        let sut = pickerWithReaction("👍")

        // THEN
        verify(matching: sut)
    }

    private func pickerWithReaction(_ reaction: String?) -> BasicReactionPicker {
        var picker = BasicReactionPicker(selectedReaction: reaction)
        picker.sizeToFit()
        picker.backgroundColor = .white
        picker.frame = CGRect(origin: .zero, size: CGSize(width: 375, height: 84))

        return picker
    }
}
