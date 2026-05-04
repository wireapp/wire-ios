//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

import WireFoundationSupport
import XCTest
@testable import Wire
@testable import WireFoundation

// MARK: - MessageActionsViewControllerTests

final class MessageActionsViewControllerTests: XCTestCase {

    // MARK: - setUp

    var mockUserDefaults = UserDefaultsProtocolMock()

    override func setUp() {
        super.setUp()

        let mockSelfUser = MockUserType.createSelfUser(name: "selfUser")
        SelfUser.provider = SelfProvider(providedSelfUser: mockSelfUser)
        mockUserDefaults.stringArrayForKeyDefaultNameStringStringReturnValue = []
        mockUserDefaults.setValueAnyForKeyDefaultNameStringVoidClosure = { _, _ in }
        mockUserDefaults.boolForKeyDefaultNameStringBoolReturnValue = false
    }

    // MARK: - Unit Tests

    func testReactionPicker_ExistForStandardMessage() {
        // GIVEN
        let message = MockMessageFactory.textMessage(withText: "Test tests")
        let actionController = ConversationMessageActionController(
            responder: nil,
            message: message,
            context: .content,
            view: UIView(),
            userDefaults: mockUserDefaults
        )
        // WHEN
        let messageActionsViewController = MessageActionsViewController.controller(
            withActions: MessageAction.allCases,
            actionController: actionController
        )
        // THEN
        XCTAssertTrue(messageActionsViewController.view.containsBasicReactionPicker())
    }

    func testReactionPicker_DoesNotExistForEphemeralMessage() {
        // GIVEN
        let message = MockMessageFactory.textMessage(withText: "Test tests")
        message.isEphemeral = true
        let actionController = ConversationMessageActionController(
            responder: nil,
            message: message,
            context: .content,
            view: UIView(),
            userDefaults: mockUserDefaults
        )
        // WHEN
        let messageActionsViewController = MessageActionsViewController.controller(
            withActions: MessageAction.allCases,
            actionController: actionController
        )
        // THEN
        XCTAssertFalse(messageActionsViewController.view.containsBasicReactionPicker())
    }

    func testReactionPicker_DoesNotExistForFailedMessage() {
        // GIVEN
        let message = MockMessageFactory.textMessage(withText: "Test tests")
        message.deliveryState = .failedToSend
        let actionController = ConversationMessageActionController(
            responder: nil,
            message: message,
            context: .content,
            view: UIView(),
            userDefaults: mockUserDefaults
        )
        // WHEN
        let messageActionsViewController = MessageActionsViewController.controller(
            withActions: MessageAction.allCases,
            actionController: actionController
        )
        // THEN
        XCTAssertFalse(messageActionsViewController.view.containsBasicReactionPicker())
    }

    func testMenuActionsForTextMessage() {
        // GIVEN
        let message = MockMessageFactory.textMessage(withText: "Test tests")
        // WHEN
        let actionsTitles = actionsTitlesForMessage(message: message)
        // THEN
        XCTAssertEqual(actionsTitles, ["Copy", "Reply", "Details", "Delete", "Cancel"])
    }

    func testMenuActionsForImageMessage() {
        // GIVEN
        let message = MockMessageFactory.imageMessage()
        // WHEN
        let actionsTitles = actionsTitlesForMessage(message: message)
        // THEN
        XCTAssertEqual(actionsTitles, ["Copy", "Reply", "Details", "Save", "Delete", "Cancel"])
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
        XCTAssertEqual(actionsTitles, ["Reply", "Details", "Download", "Delete", "Cancel"])
    }

    func testMenuActionsForLocationMessage() {
        // GIVEN
        let message = MockMessageFactory.locationMessage()
        // WHEN
        let actionsTitles = actionsTitlesForMessage(message: message)
        // THEN
        XCTAssertEqual(actionsTitles, ["Copy", "Reply", "Details", "Delete", "Cancel"])
    }

    func testMenuActionsForLinkMessage() {
        // GIVEN
        let message = MockMessageFactory.linkMessage()
        // WHEN
        let actionsTitles = actionsTitlesForMessage(message: message)
        // THEN
        XCTAssertEqual(actionsTitles, ["Visit Link", "Copy", "Reply", "Details", "Delete", "Cancel"])
    }

    func testMenuActionsForPingMessage() {
        // GIVEN
        let message = MockMessageFactory.pingMessage()
        // WHEN
        let actionsTitles = actionsTitlesForMessage(message: message)
        // THEN
        XCTAssertEqual(actionsTitles, ["Delete", "Cancel"])
    }

    func testMenuActionsForFileMessage_collapseOwnMessagesDisabled() {
        // GIVEN
        let message = MockMessageFactory.fileTransferMessage()
        // WHEN
        let actionsTitles = actionsTitlesForMessage(message: message)
        // THEN
        XCTAssertEqual(actionsTitles, ["Reply", "Details", "Download", "Delete", "Cancel"])
    }

    func testMenuActionsForFileMessage_collapseOwnMessagesEnabled() {
        // GIVEN
        let selfUser = MockUserType.createSelfUser(name: "Tarja Turunen")
        mockUserDefaults.boolForKeyDefaultNameStringBoolReturnValue = true

        let message = MockMessageFactory.fileTransferMessage()

        // WHEN
        let (actionController, _) = makeSut(
            message: message,
            sender: selfUser,
            isCollapsed: false,
            selfUserId: selfUser.remoteIdentifier
        )
        message.senderUser = selfUser

        // need to toggle it twice because of logic that
        // we only show collapse when user actually expanded at least once
        actionController.isCollapsed?.toggle()
        actionController.isCollapsed?.toggle()

        XCTAssertEqual(actionController.isCollapsed, false)

        let sut = MessageActionsViewController.controller(
            withActions: MessageAction.allCases,
            actionController: actionController
        )

        // expand message

        // THEN
        XCTAssertEqual(
            sut.titles,
            ["Collapse", "Reply", "Details", "Download", "Delete", "Cancel"]
        )
    }

    func testMenuActionsForImageMessage_collapseOwnMessagesEnabled_wasUncollapsedBefore() {
        // GIVEN
        let selfUser = MockUserType.createSelfUser(name: "Tarja Turunen")
        mockUserDefaults.boolForKeyDefaultNameStringBoolReturnValue = true

        let message = MockMessageFactory.imageMessage()
        mockUserDefaults.stringArrayForKeyDefaultNameStringStringReturnValue = [message.nonce!.uuidString]
        // WHEN
        let (actionController, _) = makeSut(
            message: message,
            sender: selfUser,
            isCollapsed: false,
            selfUserId: selfUser.remoteIdentifier
        )
        message.senderUser = selfUser

        XCTAssertEqual(actionController.isCollapsed, false)

        let sut = MessageActionsViewController.controller(
            withActions: MessageAction.allCases,
            actionController: actionController
        )

        // expand message

        // THEN
        XCTAssertEqual(
            sut.titles,
            ["Copy", "Collapse", "Reply", "Details", "Save", "Delete", "Cancel"]
        )
    }

    func testMenuActionsForFileMessage_fromOtherUser_hasNoCollapse() {
        // GIVEN
        let message = MockMessageFactory.fileTransferMessage()
        let selfUser = MockUserType.createSelfUser(name: "Tarja Turunen")
        mockUserDefaults.boolForKeyDefaultNameStringBoolReturnValue = true

        // WHEN
        let (actionController, sut) = makeSut(
            message: message,
            isCollapsed: false,
            selfUserId: selfUser.remoteIdentifier
        )
        message.senderUser = selfUser

        XCTAssertEqual(actionController.isCollapsed, false)

        // THEN
        XCTAssertEqual(sut.titles, ["Reply", "Details", "Download", "Delete", "Cancel"])
    }

    func testMenuActionsForTextMessageWithPreview_hasCollapse() {
        // GIVEN
        let message = MockMessageFactory.linkMessage()
        let selfUser = MockUserType.createSelfUser(name: "Tarja Turunen")
        mockUserDefaults.boolForKeyDefaultNameStringBoolReturnValue = true
        mockUserDefaults.stringArrayForKeyDefaultNameStringStringReturnValue = [message.nonce!.uuidString]

        // WHEN
        let (actionController, sut) = makeSut(
            message: message,
            sender: selfUser,
            isCollapsed: false,
            selfUserId: selfUser.remoteIdentifier
        )
        message.senderUser = selfUser

        XCTAssertEqual(actionController.isCollapsed, false)

        // THEN
        XCTAssertTrue(sut.titles.contains("Collapse"))
    }

    func testMenuActionsForTextMessageWithLinkAttachments_hasCollapse() {
        // GIVEN
        let message = MockMessageFactory.textMessageWithLinkAttachment()
        let selfUser = MockUserType.createSelfUser(name: "Tarja Turunen")
        mockUserDefaults.boolForKeyDefaultNameStringBoolReturnValue = true
        mockUserDefaults.stringArrayForKeyDefaultNameStringStringReturnValue = [message.nonce!.uuidString]

        // WHEN
        let (actionController, sut) = makeSut(
            message: message,
            sender: selfUser,
            isCollapsed: false,
            selfUserId: selfUser.remoteIdentifier
        )
        message.senderUser = selfUser

        XCTAssertEqual(actionController.isCollapsed, false)

        // THEN
        XCTAssertTrue(sut.titles.contains("Collapse"))
    }

    private func actionsTitlesForMessage(message: MockMessage) -> [String] {
        makeSut(message: message).1.titles
    }

    private func makeSut(
        message: MockMessage,
        sender: MockUserType? = nil,
        isCollapsed: Bool = false,
        selfUserId: UUID? = nil
    ) -> (ConversationMessageActionController, MessageActionsViewController) {
        message.senderUser = sender ?? MockUserType.createUser(name: "Bob")
        let actionController = ConversationMessageActionController(
            responder: nil,
            message: message,
            context: .content,
            view: UIView(),
            isCollapsed: isCollapsed,
            selfUserId: selfUserId,
            userDefaults: mockUserDefaults
        )
        let sut = MessageActionsViewController.controller(
            withActions: MessageAction.allCases,
            actionController: actionController
        )

        return (actionController, sut)
    }

}

// MARK: - UIView extension

private extension UIView {

    func containsBasicReactionPicker() -> Bool {
        if subviews.contains(
            where: { $0.isKind(of: BasicReactionPicker.self) }
        ) {
            return true
        }

        for subview in subviews
            where subview.containsBasicReactionPicker() {
            return true
        }

        return false
    }
}

extension MessageActionsViewController {
    var titles: [String] {
        actions.map { $0.title ?? "" }
    }
}
