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

@testable import Wire
import XCTest

final class ConversationMessageActionControllerTests: XCTestCase, CoreDataFixtureTestHelper {
    var coreDataFixture: CoreDataFixture!

    override func setUp() {
        super.setUp()
        coreDataFixture = CoreDataFixture()
    }

    override func tearDown() {
        coreDataFixture = nil
        super.tearDown()
    }

    // MARK: - Single Tap Action

    func testThatImageIsPresentedOnSingleTapWhenDownloaded() {
        // GIVEN
        let message = MockMessageFactory.imageMessage(with: image(inTestBundleNamed: "unsplash_burger.jpg"))
        message.senderUser = MockUserType.createUser(name: "Bob")
        message.conversation = otherUserConversation

        // WHEN
        let actionController = ConversationMessageActionController(responder: nil, message: message, context: .content, view: UIView())
        let singleTapAction = actionController.singleTapAction

        // THEN
        XCTAssertEqual(singleTapAction, .present)
    }

    func testThatImageIgnoresSingleTapWhenNotDownloaded() {
        // GIVEN
        let message = MockMessageFactory.imageMessage(with: nil)
        message.senderUser = MockUserType.createUser(name: "Bob")
        message.conversation = otherUserConversation

        // WHEN
        let actionController = ConversationMessageActionController(responder: nil, message: message, context: .content, view: UIView())
        let singleTapAction = actionController.singleTapAction

        // THEN
        XCTAssertNil(singleTapAction)
    }

    // MARK: - Double Tap Action

    func testThatItAllowsToLikeMessage() {
        // GIVEN
        let message = MockMessageFactory.textMessage(withText: "Super likeable")
        message.senderUser = MockUserType.createUser(name: "Bob")
        message.conversation = otherUserConversation

        // WHEN
        let actionController = ConversationMessageActionController(responder: nil, message: message, context: .content, view: UIView())
        let doubleTapAction = actionController.doubleTapAction

        // THEN
        XCTAssertEqual(doubleTapAction, .react("❤️"))
    }

    func testThatItDoesNotAllowToLikeEphemeralMessage() {
        // GIVEN
        let message = MockMessageFactory.textMessage(withText: "Super likeable")
        message.senderUser = MockUserType.createUser(name: "Bob")
        message.conversation = otherUserConversation
        message.isEphemeral = true

        // WHEN
        let actionController = ConversationMessageActionController(responder: nil, message: message, context: .content, view: UIView())
        let doubleTapAction = actionController.doubleTapAction

        // THEN
        XCTAssertNil(doubleTapAction)
    }

    // MARK: - Reply

    func testThatItDoesNotShowReplyItemForUnsentTextMessage() {
        // GIVEN
        let message = MockMessageFactory.textMessage(withText: "Text")
        message.senderUser = MockUserType.createUser(name: "Bob")
        message.conversation = otherUserConversation
        message.deliveryState = .failedToSend

        // WHEN
        let actionController = ConversationMessageActionController(responder: nil, message: message, context: .content, view: UIView())
        let supportsReply = actionController.canPerformAction(#selector(ConversationMessageActionController.quoteMessage))

        // THEN
        XCTAssertFalse(supportsReply)

    }

    // MARK: - Copy

    func testThatItShowsCopyItemForTextMessage() {
        // GIVEN
        let message = MockMessageFactory.textMessage(withText: "Text")
        message.senderUser = MockUserType.createUser(name: "Bob")
        message.conversation = otherUserConversation

        // WHEN
        let actionController = ConversationMessageActionController(responder: nil, message: message, context: .content, view: UIView())
        let supportsCopy = actionController.canPerformAction(#selector(ConversationMessageActionController.copyMessage))

        // THEN
        XCTAssertTrue(supportsCopy)
    }

    // MARK: - Save

    func testThatItDoesNotShowSaveItemForAudioMessage_IfReceivingFilesIsRestricted() {
        // GIVEN
        let message = MockMessageFactory.audioMessage()
        message!.senderUser = MockUserType.createUser(name: "Bob")
        message!.conversation = otherUserConversation
        message!.backingIsRestricted = true

        // WHEN
        let actionController = ConversationMessageActionController(responder: nil, message: message!, context: .content, view: UIView())
        let supportsSave = actionController.canPerformAction(#selector(ConversationMessageActionController.saveMessage))

        // THEN
        XCTAssertFalse(supportsSave)
    }

    // MARK: - Download

    func testThatItDoesNotShowDownloadItemForAudioMessage_IfReceivingFilesIsRestricted() {
        // GIVEN
        let message = MockMessageFactory.audioMessage()
        message!.senderUser = MockUserType.createUser(name: "Bob")
        message!.conversation = otherUserConversation
        message!.backingIsRestricted = true

        // WHEN
        let actionController = ConversationMessageActionController(responder: nil, message: message!, context: .content, view: UIView())
        let supportsDownload = actionController.canPerformAction(#selector(ConversationMessageActionController.downloadMessage))

        // THEN
        XCTAssertFalse(supportsDownload)
    }

    // MARK: - Forward

    func testThatItDoesNotShowForwardItemForAudioMessage_IfReceivingFilesIsRestricted() {
        // GIVEN
        let message = MockMessageFactory.audioMessage()
        message!.senderUser = MockUserType.createUser(name: "Bob")
        message!.conversation = otherUserConversation
        message!.backingIsRestricted = true

        // WHEN
        let actionController = ConversationMessageActionController(responder: nil, message: message!, context: .content, view: UIView())
        let supportsForward = actionController.canPerformAction(#selector(ConversationMessageActionController.forwardMessage))

        // THEN
        XCTAssertFalse(supportsForward)
    }

    func testGivenURLMessageThenSupportsVisitLink() {
        // GIVEN
        let message = MockMessageFactory.linkMessage()
        message.senderUser = MockUserType.createUser(name: "Bob")
        message.conversation = otherUserConversation

        // WHEN
        let actionController = ConversationMessageActionController(responder: nil, message: message, context: .content, view: UIView())
        let supportsVisitLink = actionController.canPerformAction(#selector(ConversationMessageActionController.visitLink(path:)))

        // THEN
        XCTAssertTrue(supportsVisitLink)
    }
}
