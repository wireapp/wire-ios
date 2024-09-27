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

import WireSyncEngineSupport
import XCTest
@testable import Wire

// MARK: - ConversationInputBarViewControllerDelegateTests

final class ConversationInputBarViewControllerDelegateTests: XCTestCase {
    // MARK: Internal

    var coreDataFixture: CoreDataFixture!
    var sut: ConversationInputBarViewController!
    var userSession: UserSessionMock!

    override func setUp() {
        super.setUp()

        coreDataFixture = CoreDataFixture()
        userSession = UserSessionMock()
    }

    override func tearDown() {
        coreDataFixture = nil
        mockDelegate = nil
        sut = nil
        userSession = nil

        super.tearDown()
    }

    func testThatDismissingQuoteUpdatesDraftAndNotifiesDelegate() {
        // Given
        let mockClassificationProvider = MockSecurityClassificationProviding()
        mockClassificationProvider.classificationUsersConversationDomain_MockValue = .notClassified

        let conversation = coreDataFixture.otherUserConversation!
        sut = ConversationInputBarViewController(
            conversation: conversation,
            userSession: userSession,
            classificationProvider: mockClassificationProvider,
            networkStatusObservable: MockNetworkStatusObservable()
        )

        mockDelegate = MockDelegate()

        sut.delegate = mockDelegate

        let message = try! conversation.appendText(content: "Boo")
        conversation.draftMessage = DraftMessage(text: "Goo", mentions: [], quote: message as? ZMMessage)
        XCTAssertTrue(conversation.hasDraftMessage)
        XCTAssertNotNil(conversation.draftMessage!.quote)

        // When dismissing the reply.
        sut.removeReplyComposingView()

        // Then the delegate was called with the updated draft.
        XCTAssertEqual(mockDelegate.composedDrafts.count, 1)
        XCTAssertEqual(mockDelegate.composedDrafts[0], DraftMessage(text: "Goo", mentions: [], quote: nil))
    }

    // MARK: Private

    private var mockDelegate: MockDelegate!
}

// MARK: - MockDelegate

private final class MockDelegate: NSObject, ConversationInputBarViewControllerDelegate {
    var composedDrafts = [DraftMessage]()

    func conversationInputBarViewControllerDidComposeText(
        text: String,
        mentions: [Mention],
        replyingTo message: ZMConversationMessage?
    ) {}

    func conversationInputBarViewControllerShouldBeginEditing(_: ConversationInputBarViewController) -> Bool {
        true
    }

    func conversationInputBarViewControllerShouldEndEditing(_: ConversationInputBarViewController) -> Bool {
        true
    }

    func conversationInputBarViewControllerDidFinishEditing(
        _ message: ZMConversationMessage,
        withText newText: String?,
        mentions: [Mention]
    ) {}

    func conversationInputBarViewControllerDidCancelEditing(_: ZMConversationMessage) {}

    func conversationInputBarViewControllerWants(toShow message: ZMConversationMessage) {}

    func conversationInputBarViewControllerEditLastMessage() {}

    func conversationInputBarViewControllerDidComposeDraft(message: DraftMessage) {
        composedDrafts.append(message)
    }
}
