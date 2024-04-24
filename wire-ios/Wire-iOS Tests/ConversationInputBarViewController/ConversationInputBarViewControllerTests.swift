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

import SnapshotTesting
import XCTest
@testable import WireCommonComponents
@testable import Wire

// In this class the snapshot tests they don't look the same as in the real app.
// The first and last button for the input bar look like they have 4 rounded corners
// instead of 2. That's because snapshot tests don't work well with maskedCorners and CI.
// More on the issue can be found here: https://github.com/pointfreeco/swift-snapshot-testing/issues/358#issuecomment-939854566
final class ConversationInputBarViewControllerTests: BaseSnapshotTestCase {

    // MARK: - Properties

    private var mockConversation: MockInputBarConversationType!
    private var mockClassificationProvider: MockClassificationProvider!
    var userSession: UserSessionMock!

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        UIColor.setAccentOverride(.red)
        mockConversation = MockInputBarConversationType()
        mockClassificationProvider = MockClassificationProvider()
        userSession = UserSessionMock()
    }

    // MARK: - tearDown

    override func tearDown() {
        mockConversation = nil
        mockClassificationProvider = nil
        userSession = nil
        super.tearDown()
    }

    func testNormalState() {
        verifyInAllPhoneWidths(createSut: {
            return ConversationInputBarViewController(conversation: mockConversation, userSession: userSession)
        })
        verifyInWidths(createSut: {
            return ConversationInputBarViewController(conversation: mockConversation, userSession: userSession)
            },
            widths: tabletWidths(),
                       snapshotBackgroundColor: .white)

    }

    // MARK: - Typing indication

    func testTypingIndicationIsShown() {
        // THEN
        let createSut: () -> UIViewController = {
            // GIVEN & WHEN
            let sut = ConversationInputBarViewController(conversation: self.mockConversation, userSession: self.userSession)

            // Directly working with sut.typingIndicatorView to prevent triggering aniamtion
            sut.typingIndicatorView.typingUsers = [MockUserType.createUser(name: "Bruno")]
            sut.typingIndicatorView.setHidden(false, animated: false)

            return sut
        }

        verifyInAllPhoneWidths(createSut: createSut)
    }

    // MARK: - Ephemeral indicator button

    func testEphemeralIndicatorButton() {
        // THEN
        let createSut: () -> UIViewController = {
            // GIVEN
            let sut = ConversationInputBarViewController(conversation: self.mockConversation, userSession: self.userSession)

            // WHEN
            sut.mode = .timeoutConfguration
            return sut
        }

        verifyInAllPhoneWidths(createSut: createSut)
    }

    func testEphemeralTimeNone() {
        // THEN
        let createSut: () -> UIViewController = {
            // GIVEN
            let sut = ConversationInputBarViewController(conversation: self.mockConversation, userSession: self.userSession)

            // WHEN
            sut.mode = .timeoutConfguration
            self.mockConversation.activeMessageDestructionTimeoutValue = nil
            return sut
        }

        verifyInAllPhoneWidths(createSut: createSut)
    }

    private func setMessageDestructionTimeout(timeInterval: TimeInterval) {
        mockConversation.activeMessageDestructionTimeoutValue = .init(rawValue: timeInterval)
    }

    func testEphemeralTime10Second() {
        // THEN
        verifyInAllPhoneWidths(createSut: {
            // GIVEN
            let sut = ConversationInputBarViewController(conversation: self.mockConversation, userSession: self.userSession)

            // WHEN
            sut.mode = .timeoutConfguration
            self.setMessageDestructionTimeout(timeInterval: 10)

            sut.inputBar.setInputBarState(.writing(ephemeral: .message), animated: false)
            return sut
        } as () -> UIViewController)
    }

    func testEphemeralTime5Minutes() {
        // THEN
        verifyInAllPhoneWidths(createSut: {
            // GIVEN
            let sut = ConversationInputBarViewController(conversation: self.mockConversation, userSession: self.userSession)

            // WHEN
            sut.mode = .timeoutConfguration
            self.setMessageDestructionTimeout(timeInterval: 300)

            sut.inputBar.setInputBarState(.writing(ephemeral: .message), animated: false)

            return sut
        } as () -> UIViewController)
    }

    func testEphemeralTime2Hours() {
        // THEN
        verifyInAllPhoneWidths(createSut: {
            // GIVEN
            let sut = ConversationInputBarViewController(conversation: self.mockConversation, userSession: self.userSession)

            // WHEN
            sut.mode = .timeoutConfguration
            self.setMessageDestructionTimeout(timeInterval: 7200)

            sut.inputBar.setInputBarState(.writing(ephemeral: .message), animated: false)

            return sut
        } as () -> UIViewController)
    }

    func testEphemeralTime3Days() {
        // THEN
        verifyInAllPhoneWidths(createSut: {
            // GIVEN
            let sut = ConversationInputBarViewController(conversation: self.mockConversation, userSession: self.userSession)

            // WHEN
            sut.mode = .timeoutConfguration
            self.setMessageDestructionTimeout(timeInterval: 259200)

            sut.inputBar.setInputBarState(.writing(ephemeral: .message), animated: false)

            return sut
        } as () -> UIViewController)
    }

    func testEphemeralTime4Weeks() {
        // THEN
        verifyInAllPhoneWidths(createSut: {
            // GIVEN
            let sut = ConversationInputBarViewController(conversation: self.mockConversation, userSession: self.userSession)

            // WHEN
            sut.mode = .timeoutConfguration
            self.setMessageDestructionTimeout(timeInterval: 2419200)

            sut.inputBar.setInputBarState(.writing(ephemeral: .message), animated: false)

            return sut
        } as () -> UIViewController)
    }

    func testEphemeralModeWhenTyping() {
        // THEN
        verifyInAllPhoneWidths(createSut: {
            // GIVEN
            let sut = ConversationInputBarViewController(conversation: self.mockConversation, userSession: self.userSession)

            // WHEN
            sut.mode = .timeoutConfguration
            self.setMessageDestructionTimeout(timeInterval: 2419200)

            sut.inputBar.setInputBarState(.writing(ephemeral: .message), animated: false)
            let shortText = "Lorem ipsum dolor"
            sut.inputBar.textView.text = shortText

            return sut
        } as () -> UIViewController)
    }

    func testEphemeralDisabled() {
        // THEN
        verifyInAllPhoneWidths(createSut: {
            // GIVEN
            self.mockConversation.isSelfDeletingMessageSendingDisabled = true
            let sut = ConversationInputBarViewController(conversation: self.mockConversation, userSession: self.userSession)

            // WHEN
            sut.mode = .timeoutConfguration

            return sut
        } as () -> UIViewController)
    }

    func testEphemeralWithForcedTimeout() {
        // THEN
        verifyInAllPhoneWidths(createSut: {
            // GIVEN
            self.mockConversation.isSelfDeletingMessageTimeoutForced = true
            let sut = ConversationInputBarViewController(conversation: self.mockConversation, userSession: self.userSession)

            // WHEN
            sut.mode = .timeoutConfguration
            self.setMessageDestructionTimeout(timeInterval: 300)

            sut.inputBar.setInputBarState(.writing(ephemeral: .message), animated: false)

            return sut
        } as () -> UIViewController)
    }

    // MARK: - file action sheet

    func testUploadFileActionSheet() throws {
        let sut = ConversationInputBarViewController(conversation: mockConversation, userSession: self.userSession)

        let alert: UIAlertController = sut.createDocUploadActionSheet()

        try verify(matching: alert)
    }

    // MARK: - Classification

    func testClassifiedNormalState() {
        verifyInAllPhoneWidths(createSut: {
            self.mockClassificationProvider.returnClassification = .classified

            return ConversationInputBarViewController(conversation: self.mockConversation, userSession: self.userSession, classificationProvider: self.mockClassificationProvider)
        } as () -> UIViewController)
    }

    func testNotClassifiedNormalState() {
        verifyInAllPhoneWidths(createSut: {
            self.mockClassificationProvider.returnClassification = .notClassified

            return ConversationInputBarViewController(conversation: self.mockConversation, userSession: self.userSession, classificationProvider: self.mockClassificationProvider)
        } as () -> UIViewController)
    }

    func testClassifiedWithTypingIndicator() {
        verifyInAllPhoneWidths(createSut: {
            self.mockClassificationProvider.returnClassification = .classified

            let sut = ConversationInputBarViewController(
                conversation: self.mockConversation, userSession: self.userSession,
                classificationProvider: self.mockClassificationProvider
            )

            sut.typingIndicatorView.typingUsers = [MockUserType.createUser(name: "Bruno")]
            sut.typingIndicatorView.setHidden(false, animated: false)

            return sut
        } as () -> UIViewController)
    }

    func testNoClassificationNormalState() {
        verifyInAllPhoneWidths(createSut: {
            self.mockClassificationProvider.returnClassification = .none

            return ConversationInputBarViewController(conversation: self.mockConversation, userSession: self.userSession, classificationProvider: self.mockClassificationProvider)
        } as () -> UIViewController)
    }

}
