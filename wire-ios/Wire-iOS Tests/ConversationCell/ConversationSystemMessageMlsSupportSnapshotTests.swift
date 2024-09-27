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

import XCTest
@testable import Wire

final class ConversationSystemMessageMlsSupportSnapshotTests: ConversationMessageSnapshotTestCase {
    // MARK: Internal

    // MARK: - Properties

    var mockConversation: SwiftMockConversation!
    var otherUser: MockUserType!

    // MARK: - setUp

    override func setUp() {
        super.setUp()

        otherUser = MockUserType.createDefaultOtherUser()
        mockConversation = SwiftMockConversation.oneOnOneConversation(otherUser: otherUser)
    }

    // MARK: - tearDown

    override func tearDown() {
        otherUser = nil
        mockConversation = nil

        super.tearDown()
    }

    // MARK: - Snapshot Tests

    func testMLSNotSupportedForSelfUser() {
        let message = makeMessage(messageType: .mlsNotSupportedSelfUser)
        verify(message: message)
    }

    func testMlsNotSupportedForOtherUser() {
        let message = makeMessage(messageType: .mlsNotSupportedOtherUser)
        verify(message: message)
    }

    // MARK: Private

    // MARK: - Helpers

    private func makeMessage(messageType: ZMSystemMessageType) -> MockMessage {
        MockMessageFactory.systemMessage(with: messageType, conversation: mockConversation)!
    }
}
