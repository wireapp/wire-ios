//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

import WireDataModel
import XCTest

@testable import Wire

final class ConversationListViewModelFilterTests: XCTestCase {

    var sut: ConversationListViewModel!
    var mockUserSession: UserSessionMock!
    var coreDataFixture: CoreDataFixture!

    override func setUp() {
        super.setUp()

        coreDataFixture = CoreDataFixture()
        mockUserSession = UserSessionMock()
        sut = ConversationListViewModel(userSession: mockUserSession)
    }

    override func tearDown() {
        sut = nil
        mockUserSession = nil
        coreDataFixture = nil

        super.tearDown()
    }

    // MARK: - Unread Filter Tests

    func testUnreadFilterPredicate_ShowsConversationWithUnreadMessages() {
        // GIVEN
        let conversation = MockConversation()
        conversation.estimatedUnreadCount = 5
        let sectionItem = ConversationListViewModel.SectionItem(
            item: conversation,
            kind: .conversations
        )

        // WHEN
        let predicate = sut.conversationFilterPredicate(for: .unread)

        // THEN
        XCTAssertNotNil(predicate)
        XCTAssertTrue(predicate?(sectionItem) ?? false)
    }

    func testUnreadFilterPredicate_HidesConversationWithoutUnreadMessages() {
        // GIVEN
        let conversation = MockConversation()
        conversation.estimatedUnreadCount = 0
        let sectionItem = ConversationListViewModel.SectionItem(
            item: conversation,
            kind: .conversations
        )

        // WHEN
        let predicate = sut.conversationFilterPredicate(for: .unread)

        // THEN
        XCTAssertNotNil(predicate)
        XCTAssertFalse(predicate?(sectionItem) ?? true)
    }

    // MARK: - Mentions Filter Tests

    func testMentionsFilterPredicate_ShowsConversationWithMentions() {
        // GIVEN
        let conversation = MockConversation()
        let message = MockMessage()
        let textData = MockTextMessageData()
        textData.isMentioningSelf = true
        message.backingTextMessageData = textData
        conversation.unreadMessages = [message]

        let sectionItem = ConversationListViewModel.SectionItem(
            item: conversation,
            kind: .conversations
        )

        // WHEN
        let predicate = sut.conversationFilterPredicate(for: .mentions)

        // THEN
        XCTAssertNotNil(predicate)
        XCTAssertTrue(predicate?(sectionItem) ?? false)
    }

    func testMentionsFilterPredicate_HidesConversationWithoutMentions() {
        // GIVEN
        let conversation = MockConversation()
        let message = MockMessage()
        let textData = MockTextMessageData()
        textData.isMentioningSelf = false
        message.backingTextMessageData = textData
        conversation.unreadMessages = [message]

        let sectionItem = ConversationListViewModel.SectionItem(
            item: conversation,
            kind: .conversations
        )

        // WHEN
        let predicate = sut.conversationFilterPredicate(for: .mentions)

        // THEN
        XCTAssertNotNil(predicate)
        XCTAssertFalse(predicate?(sectionItem) ?? true)
    }

    // MARK: - Replies Filter Tests

    func testRepliesFilterPredicate_ShowsConversationWithRepliesToSelf() {
        // GIVEN
        let conversation = MockConversation()
        let message = MockMessage()
        let textData = MockTextMessageData()
        textData.isQuotingSelf = true
        message.backingTextMessageData = textData
        conversation.unreadMessages = [message]

        let sectionItem = ConversationListViewModel.SectionItem(
            item: conversation,
            kind: .conversations
        )

        // WHEN
        let predicate = sut.conversationFilterPredicate(for: .replies)

        // THEN
        XCTAssertNotNil(predicate)
        XCTAssertTrue(predicate?(sectionItem) ?? false)
    }

    func testRepliesFilterPredicate_HidesConversationWithoutRepliesToSelf() {
        // GIVEN
        let conversation = MockConversation()
        let message = MockMessage()
        let textData = MockTextMessageData()
        textData.isQuotingSelf = false
        message.backingTextMessageData = textData
        conversation.unreadMessages = [message]

        let sectionItem = ConversationListViewModel.SectionItem(
            item: conversation,
            kind: .conversations
        )

        // WHEN
        let predicate = sut.conversationFilterPredicate(for: .replies)

        // THEN
        XCTAssertNotNil(predicate)
        XCTAssertFalse(predicate?(sectionItem) ?? true)
    }

    // MARK: - No Filter Tests

    func testNoFilterPredicate_ReturnsNil() {
        // WHEN
        let predicate = sut.conversationFilterPredicate(for: nil)

        // THEN
        XCTAssertNil(predicate)
    }

    func testOtherFilterPredicate_ReturnsNil() {
        // WHEN
        let predicateGroups = sut.conversationFilterPredicate(for: .groups)
        let predicateFavorites = sut.conversationFilterPredicate(for: .favorites)

        // THEN
        XCTAssertNil(predicateGroups)
        XCTAssertNil(predicateFavorites)
    }
}

// MARK: - Mock Classes

private class MockConversation: NSObject, ZMConversation {
    var estimatedUnreadCount: Int32 = 0
    var unreadMessages: [ZMConversationMessage] = []

    // Required protocol stubs
    var conversationType: ZMConversationType = .group
    var isSelfAnActiveMember: Bool = true
    var isArchived: Bool = false
    var isFavorite: Bool = false
    var isPendingConnectionConversation: Bool = false
    var remoteIdentifier: UUID? = UUID()
    var teamRemoteIdentifier: UUID?
    var userDefinedName: String?
    var lastServerTimeStamp: Date?
    var lastReadServerTimeStamp: Date?
}

private class MockMessage: NSObject, ZMConversationMessage {
    var backingTextMessageData: MockTextMessageData?

    var textMessageData: ZMTextMessageData? {
        backingTextMessageData
    }

    // Required protocol stubs
    var nonce: UUID? = UUID()
    var serverTimestamp: Date?
    var conversation: ZMConversation?
    var sender: UserType?
    var senderClientID: String?
}

private class MockTextMessageData: NSObject, ZMTextMessageData {
    var isMentioningSelf: Bool = false
    var isQuotingSelf: Bool = false

    // Required protocol stubs
    var messageText: String?
    var linkPreview: LinkPreview?
    var mentions: [Mention] = []
    var quote: ZMMessage?
    var hasQuote: Bool = false
}
