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

    func testReactionPicker_ExistForStandardMessage() {
        // GIVEN
        let message = MockMessageFactory.textMessage(withText: "Test tests")
        let actionController = ConversationMessageActionController(responder: nil, message: message, context: .content, view: UIView())
        // WHEN
        let messageActionsViewController = MessageActionsViewController.controller(withActions: MessageAction.allCases,
                                                                            actionController: actionController)
        // THEN
        XCTAssertTrue(messageActionsViewController.view.containsBasicReactionPicker())
    }

    func testReactionPicker_DoesNotExistForEphemeralMessage() {
        // GIVEN
        let message = MockMessageFactory.textMessage(withText: "Test tests")
        message.isEphemeral = true
        let actionController = ConversationMessageActionController(responder: nil, message: message, context: .content, view: UIView())
        // WHEN
        let messageActionsViewController = MessageActionsViewController.controller(withActions: MessageAction.allCases,
                                                                            actionController: actionController)
        // THEN
        XCTAssertFalse(messageActionsViewController.view.containsBasicReactionPicker())
    }

    func testReactionPicker_DoesNotExistForFailedMessage() {
        // GIVEN
        let message = MockMessageFactory.textMessage(withText: "Test tests")
        message.deliveryState = .failedToSend
        let actionController = ConversationMessageActionController(responder: nil, message: message, context: .content, view: UIView())
        // WHEN
        let messageActionsViewController = MessageActionsViewController.controller(withActions: MessageAction.allCases,
                                                                            actionController: actionController)
        // THEN
        XCTAssertFalse(messageActionsViewController.view.containsBasicReactionPicker())
    }

    func testMenuActionsForTextMessage() {
        // GIVEN
        let message = MockMessageFactory.textMessage(withText: "Test tests")
        // WHEN
        let actionsTitles = actionsTitlesForMessage(message: message)
        // THEN
        XCTAssertArrayEqual(actionsTitles, ["Copy", "Reply", "Details", "Share", "Delete", "Cancel"])
    }

    func testMenuActionsForImageMessage() {
        // GIVEN
        let message = MockMessageFactory.imageMessage()
        // WHEN
        let actionsTitles = actionsTitlesForMessage(message: message)
        // THEN
        XCTAssertArrayEqual(actionsTitles, ["Copy", "Reply", "Details", "Save", "Share", "Delete", "Cancel"])
    }

    func testMenuActionsForAudioMessage() {
        // GIVEN
        guard let message = MockMessageFactory.audioMessage() else {
            XCTFail("audio message shouldn't be nil")
            return
        }
        // WHEN
        let actionsTitles = actionsTitlesForMessage(message: message)
        // THEN
        XCTAssertArrayEqual(actionsTitles, ["Reply", "Details", "Download", "Delete", "Cancel"])
    }

    func testMenuActionsForLocationMessage() {
        // GIVEN
        let message = MockMessageFactory.locationMessage()
        // WHEN
        let actionsTitles = actionsTitlesForMessage(message: message)
        // THEN
        XCTAssertArrayEqual(actionsTitles, ["Copy", "Reply", "Details", "Share", "Delete", "Cancel"])
    }

    func testMenuActionsForLinkMessage() {
        // GIVEN
        guard let message = MockMessageFactory.linkMessage() else {
            XCTFail("link message shouldn't be nil")
            return
        }
        // WHEN
        let actionsTitles = actionsTitlesForMessage(message: message)
        // THEN
        XCTAssertArrayEqual(actionsTitles, ["Copy", "Reply", "Details", "Share", "Delete", "Cancel"])
    }

    func testMenuActionsForPingMessage() {
        // GIVEN
        let message = MockMessageFactory.pingMessage()
        // WHEN
        let actionsTitles = actionsTitlesForMessage(message: message)
        // THEN
        XCTAssertArrayEqual(actionsTitles, ["Delete", "Cancel"])
    }

    func actionsTitlesForMessage(message: MockMessage) -> [String] {
        message.senderUser = MockUserType.createUser(name: "Bob")
        let actionController = ConversationMessageActionController(responder: nil, message: message, context: .content, view: UIView())
        let sut = MessageActionsViewController.controller(withActions: MessageAction.allCases, actionController: actionController)

        return sut.actions.map { $0.title ?? "" }
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
        let sut = pickerWithReaction([Emoji.thumbsUp])

        // THEN
        verify(matching: sut)
    }

    private func pickerWithReaction(_ reaction: Set<Emoji>?) -> BasicReactionPicker {
        var picker = BasicReactionPicker(selectedReactions: reaction ?? [])
        picker.sizeToFit()
        picker.backgroundColor = .white
        picker.frame = CGRect(origin: .zero, size: CGSize(width: 375, height: 84))

        return picker
    }
}

fileprivate extension UIView {

    func containsBasicReactionPicker() -> Bool {
        if self.subviews.contains(where: { $0.isKind(of: BasicReactionPicker.self) }) {
                    return true
                }

                for subview in self.subviews {
                    if subview.containsBasicReactionPicker() {
                        return true
                    }
                }

                return false
    }
}
