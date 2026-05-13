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

import XCTest

@testable import Wire

final class ConversationPreviewViewModelTests: XCTestCase {

    func testStateMapsConversationTitleAndPreviewActions() {
        let conversation = ZMConversation()
        conversation.displayName = "Design"

        let sut = ConversationPreviewViewModel(
            conversation: conversation,
            actions: [.archive(isArchived: false), .delete]
        )

        XCTAssertEqual(sut.state.title, "Design")
        XCTAssertEqual(sut.state.content, .ready)
        XCTAssertEqual(
            sut.state.actions,
            [
                .init(
                    conversationAction: .archive(isArchived: false),
                    title: L10n.Localizable.Meta.Menu.archive,
                    style: .default
                ),
                .init(
                    conversationAction: .delete,
                    title: L10n.Localizable.Meta.Menu.delete,
                    style: .destructive
                )
            ]
        )
    }

    func testRouteForPreviewActionReturnsConversationAction() {
        let sut = ConversationPreviewViewModel(
            conversation: ZMConversation(),
            actions: [.clearContent]
        )

        guard case let .performConversationAction(action) = sut.routeForPreviewAction(at: 0) else {
            return XCTFail("Expected conversation action route")
        }

        XCTAssertEqual(action, .clearContent)
    }

    func testRouteForInvalidPreviewActionDismissesPreview() {
        let sut = ConversationPreviewViewModel(
            conversation: ZMConversation(),
            actions: [.clearContent]
        )

        guard case .dismissPreview = sut.routeForPreviewAction(at: 1) else {
            return XCTFail("Expected dismiss route")
        }
    }
}
