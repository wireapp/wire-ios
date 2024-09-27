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

import Foundation
import WireDataModel
import XCTest
@testable import Wire
@testable import WireDataModelSupport

final class ConversationMissedCallSystemMessageViewModelTests: XCTestCase {
    func testAttributedTitle_givenInitialState() {
        // given
        let viewModel = makeViewModel()

        // when
        let title = viewModel.attributedTitle()

        // then
        XCTAssertNil(title)
    }

    func testAttributedTitle_givenZeroChildMessages() {
        // given
        let mockMessage = makeMessage()
        let viewModel = makeViewModel(message: mockMessage)

        // when
        let title = viewModel.attributedTitle()

        // then
        XCTAssertEqual(title?.string, "Missed call")
    }

    func testAttributedTitle_givenOneChildMessages() {
        // given
        let mockMessage = makeMessage(childMessages: ["1"])
        let viewModel = makeViewModel(message: mockMessage)

        // when
        let title = viewModel.attributedTitle()

        // then
        XCTAssertEqual(title?.string, "Missed calls (2)")
    }

    func testAttributedTitle_givenZeroChildMessagesInGroup() {
        // given
        let mockConversationLike = MockConversationLike()
        mockConversationLike.conversationType = .group

        let mockUserType = MockUserType()
        mockUserType.name = "John Appleseed"

        let mockMessage = makeMessage(
            senderUser: mockUserType,
            conversationLike: mockConversationLike
        )
        let viewModel = makeViewModel(message: mockMessage)

        // when
        let title = viewModel.attributedTitle()

        // then
        XCTAssertEqual(title?.string, "Missed call from John Appleseed")
    }

    func testAttributedTitle_givenOneChildMessagesInGroup() {
        // given
        let mockConversationLike = MockConversationLike()
        mockConversationLike.conversationType = .group

        let mockUserType = MockUserType()
        mockUserType.name = "John Appleseed"

        let mockMessage = makeMessage(
            childMessages: ["1"],
            senderUser: mockUserType,
            conversationLike: mockConversationLike
        )
        let viewModel = makeViewModel(message: mockMessage)

        // when
        let title = viewModel.attributedTitle()

        // then
        XCTAssertEqual(title?.string, "Missed calls from John Appleseed (2)")
    }

    // MARK: - Helpers

    private func makeViewModel(message: ZMConversationMessage? = nil) -> ConversationMissedCallSystemMessageViewModel {
        ConversationMissedCallSystemMessageViewModel(
            icon: .missedCall,
            iconColor: .label,
            systemMessageType: .missedCall,
            font: .preferredFont(forTextStyle: .body),
            textColor: .label,
            message: message ?? MockMessage()
        )
    }

    private func makeMessage(
        childMessages: Set<AnyHashable>? = nil,
        senderUser: UserType? = nil,
        conversationLike: ConversationLike? = nil
    ) -> ZMConversationMessage {
        let systemMessageData = MockSystemMessageData(systemMessageType: .missedCall, reason: .none)
        systemMessageData.childMessages = childMessages ?? .init()

        let message = MockMessage()
        message.backingSystemMessageData = systemMessageData
        message.conversationLike = conversationLike
        message.senderUser = senderUser ?? MockUserType()

        return message
    }
}
