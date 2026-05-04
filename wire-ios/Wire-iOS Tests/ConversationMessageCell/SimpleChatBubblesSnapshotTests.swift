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

import GenericMessageProtocol
import XCTest

@testable import Wire

final class SimpleChatBubblesSnapshotTests: ConversationMessageSnapshotTestCase {

    private let record: Bool? = nil

    // MARK: - Snapshot Tests

    func testSelfMessageDefaultColor() {
        let message = createMessage(isFromSelfUser: true)
        verify(message: message, record: record)
    }

    func testSelfMessagePurpleColor() {
        let message = createMessage(isFromSelfUser: true, color: .purple)
        verify(message: message, record: record)
    }

    func testSelfMessageNumberedList() {
        let textWithNumberedList =
            "1. Lorem ipsum dolor sit amet, consectetuer adipiscing elit.\n2. Aenean commodo ligula eget dolor.\n3. Aenean massa."
        let message = createMessage(withText: textWithNumberedList, isFromSelfUser: true)
        verify(message: message, record: record)
    }

    func testSelfMessageCollapsed() {
        mockUserDefaults.boolForKeyDefaultNameStringBoolReturnValue = true

        let message = createMessage(isFromSelfUser: true)
        verify(message: message, record: record)

        mockUserDefaults.boolForKeyDefaultNameStringBoolReturnValue = false
    }

    func testOtherMessage() {
        let message = createMessage(isFromSelfUser: false)
        verify(message: message, record: record)
    }

    // MARK: - Helper Methods

    func createMessage(
        withText: String =
            "Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Aenean commodo ligula eget dolor. Aenean massa. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Donec quam felis, ultricies nec, pellentesque eu, pretium quis, sem.",
        userName: String = "Bruno",
        isFromSelfUser: Bool,
        color: ZMAccentColor = .default
    ) -> MockMessage {
        let message = MockMessageFactory.textMessage(withText: withText)
        let user = MockUserType.createConnectedUser(name: userName, isSelfUser: isFromSelfUser, color: color)
        message.senderUser = user

        return message
    }
}
