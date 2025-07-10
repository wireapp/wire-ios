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

final class ConversationListViewModelFilterIntegrationTests: XCTestCase {

    private var sut: ConversationListViewModel!
    private var mockUserSession: UserSessionMock!
    private var mockConversationListViewModelDelegate: MockConversationListViewModelDelegate!
    private var coreDataFixture: CoreDataFixture!

    override func setUp() {
        super.setUp()

        mockUserSession = UserSessionMock()
        sut = ConversationListViewModel(userSession: mockUserSession)

        mockConversationListViewModelDelegate = MockConversationListViewModelDelegate()
        sut.delegate = mockConversationListViewModelDelegate

        coreDataFixture = CoreDataFixture()
    }

    override func tearDown() {
        sut = nil
        mockUserSession = nil
        mockConversationListViewModelDelegate = nil
        coreDataFixture = nil

        super.tearDown()
    }

    // MARK: - Filter Switching Tests

    func testSwitchingBetweenFilters() {
        // GIVEN
        let conversationWithUnread = createConversationWithUnread()
        let conversationWithMention = createConversationWithUnreadMention()
        let conversationWithReply = createConversationWithUnreadReply()
        let conversationNoUnread = createConversationWithoutUnread()

        mockUserSession.mockConversationDirectory.mockUnarcchivedConversations = [
            conversationWithUnread,
            conversationWithMention,
            conversationWithReply,
            conversationNoUnread
        ]

        let info = ConversationDirectoryChangeInfo(
            reloaded: true,
            updatedLists: [.unarchived],
            updatedFolders: false
        )

        // Test unread filter
        sut.selectedFilter = .unread
        sut.conversationDirectoryDidChange(
            conversationDirectory: mockUserSession.mockConversationDirectory,
            changeInfo: info
        )
        XCTAssertEqual(sut.section(at: 0)?.count, 3, "Unread filter should show 3 conversations")

        // Switch to mentions filter
        sut.selectedFilter = .mentions
        sut.conversationDirectoryDidChange(
            conversationDirectory: mockUserSession.mockConversationDirectory,
            changeInfo: info
        )
        XCTAssertEqual(sut.section(at: 0)?.count, 1, "Mentions filter should show 1 conversation")

        // Switch to replies filter
        sut.selectedFilter = .replies
        sut.conversationDirectoryDidChange(
            conversationDirectory: mockUserSession.mockConversationDirectory,
            changeInfo: info
        )
        XCTAssertEqual(sut.section(at: 0)?.count, 1, "Replies filter should show 1 conversation")

        // Switch back to no filter
        sut.selectedFilter = nil
        sut.conversationDirectoryDidChange(
            conversationDirectory: mockUserSession.mockConversationDirectory,
            changeInfo: info
        )
        XCTAssertEqual(sut.section(at: 0)?.count, 4, "No filter should show all 4 conversations")
    }

    // MARK: - Dynamic Update Tests

    func testFilterUpdatesWhenConversationStateChanges() {
        // GIVEN
        let conversation = createConversationWithoutUnread()
        mockUserSession.mockConversationDirectory.mockUnarcchivedConversations = [conversation]

        sut.selectedFilter = .unread
        let info = ConversationDirectoryChangeInfo(
            reloaded: true,
            updatedLists: [.unarchived],
            updatedFolders: false
        )

        sut.conversationDirectoryDidChange(
            conversationDirectory: mockUserSession.mockConversationDirectory,
            changeInfo: info
        )

        // Initially empty
        XCTAssertEqual(sut.section(at: 0)?.count, 0, "Should have no conversations initially")

        // WHEN - Add unread message
        coreDataFixture.uiMOC.performGroupedBlockAndWait {
            let message = try! conversation.appendText(content: "New unread message") as! ZMClientMessage
            message.serverTimestamp = Date()
            conversation.updateTimestampsAfterUpdatingMessage(message)
            conversation.lastReadServerTimeStamp = Date(timeIntervalSinceNow: -60)
            conversation.needsToCalculateUnreadMessages = true
            ZMConversation.calculateLastUnreadMessages(in: self.coreDataFixture.uiMOC)
        }

        // Update
        sut.conversationDirectoryDidChange(
            conversationDirectory: mockUserSession.mockConversationDirectory,
            changeInfo: info
        )

        // THEN
        XCTAssertEqual(sut.section(at: 0)?.count, 1, "Should show conversation after it becomes unread")
    }

    // MARK: - Search Integration Tests

    func testFilterWorksWithSearch() {
        // GIVEN
        let conversationMatch = createConversationWithUnread()
        conversationMatch.userDefinedName = "Team Discussion"

        let conversationNoMatch = createConversationWithUnread()
        conversationNoMatch.userDefinedName = "Random Chat"

        mockUserSession.mockConversationDirectory.mockUnarcchivedConversations = [
            conversationMatch,
            conversationNoMatch
        ]

        sut.selectedFilter = .unread
        sut.appliedSearchText = "Team"

        // WHEN
        let info = ConversationDirectoryChangeInfo(
            reloaded: true,
            updatedLists: [.unarchived],
            updatedFolders: false
        )
        sut.conversationDirectoryDidChange(
            conversationDirectory: mockUserSession.mockConversationDirectory,
            changeInfo: info
        )

        // THEN
        let items = sut.section(at: 0) ?? []
        XCTAssertEqual(items.count, 1, "Should show only matching conversation")
        XCTAssertEqual((items.first as? ZMConversation)?.userDefinedName, "Team Discussion")
    }

    // MARK: - Multiple Filters Combination Tests

    func testConversationMatchingMultipleFilters() {
        // GIVEN - Conversation with both mention and reply
        let conversation = ZMConversation.createTeamGroupConversation(
            moc: coreDataFixture.uiMOC,
            otherUser: coreDataFixture.otherUser,
            selfUser: coreDataFixture.selfUser
        )
        conversation.userDefinedName = "Multi-match"

        coreDataFixture.uiMOC.performGroupedBlockAndWait {
            // Add unread mention
            let mention = Mention(range: NSRange(location: 0, length: 5), user: self.coreDataFixture.selfUser)
            let mentionMessage = try! conversation.appendText(
                content: "@self check this",
                mentions: [mention],
                replyingTo: nil,
                fetchLinkPreview: false,
                nonce: UUID()
            ) as! ZMClientMessage
            mentionMessage.serverTimestamp = Date()

            // Add unread reply
            let originalMessage = try! conversation.appendText(content: "Original") as! ZMClientMessage
            originalMessage.sender = self.coreDataFixture.selfUser
            originalMessage.serverTimestamp = Date(timeIntervalSinceNow: -180)

            let replyMessage = try! conversation.appendText(
                content: "Reply to you",
                mentions: [],
                replyingTo: originalMessage,
                fetchLinkPreview: false,
                nonce: UUID()
            ) as! ZMClientMessage
            replyMessage.sender = self.coreDataFixture.otherUser
            replyMessage.serverTimestamp = Date()

            conversation.updateTimestampsAfterUpdatingMessage(mentionMessage)
            conversation.updateTimestampsAfterUpdatingMessage(replyMessage)
            conversation.lastReadServerTimeStamp = Date(timeIntervalSinceNow: -60)
            conversation.needsToCalculateUnreadMessages = true
            ZMConversation.calculateLastUnreadMessages(in: self.coreDataFixture.uiMOC)
        }

        mockUserSession.mockConversationDirectory.mockUnarcchivedConversations = [conversation]

        let info = ConversationDirectoryChangeInfo(
            reloaded: true,
            updatedLists: [.unarchived],
            updatedFolders: false
        )

        // Test that conversation appears in all relevant filters

        // Unread filter
        sut.selectedFilter = .unread
        sut.conversationDirectoryDidChange(
            conversationDirectory: mockUserSession.mockConversationDirectory,
            changeInfo: info
        )
        XCTAssertEqual(sut.section(at: 0)?.count, 1, "Should appear in unread filter")

        // Mentions filter
        sut.selectedFilter = .mentions
        sut.conversationDirectoryDidChange(
            conversationDirectory: mockUserSession.mockConversationDirectory,
            changeInfo: info
        )
        XCTAssertEqual(sut.section(at: 0)?.count, 1, "Should appear in mentions filter")

        // Replies filter
        sut.selectedFilter = .replies
        sut.conversationDirectoryDidChange(
            conversationDirectory: mockUserSession.mockConversationDirectory,
            changeInfo: info
        )
        XCTAssertEqual(sut.section(at: 0)?.count, 1, "Should appear in replies filter")
    }

    // MARK: - Performance Tests

    func testFilterPerformanceWithManyConversations() {
        // GIVEN - Create many conversations
        var conversations: [ZMConversation] = []

        coreDataFixture.uiMOC.performGroupedBlockAndWait {
            for i in 0 ..< 100 {
                let conversation = ZMConversation.createTeamGroupConversation(
                    moc: self.coreDataFixture.uiMOC,
                    otherUser: self.coreDataFixture.otherUser,
                    selfUser: self.coreDataFixture.selfUser
                )
                conversation.userDefinedName = "Conversation \(i)"

                // Add unread messages to half of them
                if i % 2 == 0 {
                    let message = try! conversation.appendText(content: "Message \(i)") as! ZMClientMessage
                    message.serverTimestamp = Date()
                    conversation.updateTimestampsAfterUpdatingMessage(message)
                    conversation.lastReadServerTimeStamp = Date(timeIntervalSinceNow: -60)
                }

                // Add mentions to 25%
                if i % 4 == 0 {
                    let mention = Mention(range: NSRange(location: 0, length: 5), user: self.coreDataFixture.selfUser)
                    let message = try! conversation.appendText(
                        content: "@self message \(i)",
                        mentions: [mention],
                        replyingTo: nil,
                        fetchLinkPreview: false,
                        nonce: UUID()
                    ) as! ZMClientMessage
                    message.serverTimestamp = Date()
                    conversation.updateTimestampsAfterUpdatingMessage(message)
                    conversation.lastReadServerTimeStamp = Date(timeIntervalSinceNow: -60)
                }

                conversation.needsToCalculateUnreadMessages = true
                conversations.append(conversation)
            }

            ZMConversation.calculateLastUnreadMessages(in: self.coreDataFixture.uiMOC)
        }

        mockUserSession.mockConversationDirectory.mockUnarcchivedConversations = conversations

        // WHEN - Measure filter performance
        sut.selectedFilter = .unread

        let startTime = CFAbsoluteTimeGetCurrent()

        let info = ConversationDirectoryChangeInfo(
            reloaded: true,
            updatedLists: [.unarchived],
            updatedFolders: false
        )
        sut.conversationDirectoryDidChange(
            conversationDirectory: mockUserSession.mockConversationDirectory,
            changeInfo: info
        )

        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime

        // THEN
        XCTAssertEqual(sut.section(at: 0)?.count, 50, "Should show 50 conversations with unread")
        XCTAssertLessThan(timeElapsed, 0.1, "Filtering should complete in less than 100ms")
    }

    // MARK: - Helper Methods

    private func createConversationWithUnread() -> ZMConversation {
        let conversation = ZMConversation.createTeamGroupConversation(
            moc: coreDataFixture.uiMOC,
            otherUser: coreDataFixture.otherUser,
            selfUser: coreDataFixture.selfUser
        )

        coreDataFixture.uiMOC.performGroupedBlockAndWait {
            let message = try! conversation.appendText(content: "Unread message") as! ZMClientMessage
            message.serverTimestamp = Date()
            conversation.updateTimestampsAfterUpdatingMessage(message)
            conversation.lastReadServerTimeStamp = Date(timeIntervalSinceNow: -60)
            conversation.needsToCalculateUnreadMessages = true
            ZMConversation.calculateLastUnreadMessages(in: self.coreDataFixture.uiMOC)
        }

        return conversation
    }

    private func createConversationWithUnreadMention() -> ZMConversation {
        let conversation = ZMConversation.createTeamGroupConversation(
            moc: coreDataFixture.uiMOC,
            otherUser: coreDataFixture.otherUser,
            selfUser: coreDataFixture.selfUser
        )

        coreDataFixture.uiMOC.performGroupedBlockAndWait {
            let mention = Mention(range: NSRange(location: 0, length: 5), user: self.coreDataFixture.selfUser)
            let message = try! conversation.appendText(
                content: "@self hello",
                mentions: [mention],
                replyingTo: nil,
                fetchLinkPreview: false,
                nonce: UUID()
            ) as! ZMClientMessage
            message.serverTimestamp = Date()
            conversation.updateTimestampsAfterUpdatingMessage(message)
            conversation.lastReadServerTimeStamp = Date(timeIntervalSinceNow: -60)
            conversation.needsToCalculateUnreadMessages = true
            ZMConversation.calculateLastUnreadMessages(in: self.coreDataFixture.uiMOC)
        }

        return conversation
    }

    private func createConversationWithUnreadReply() -> ZMConversation {
        let conversation = ZMConversation.createTeamGroupConversation(
            moc: coreDataFixture.uiMOC,
            otherUser: coreDataFixture.otherUser,
            selfUser: coreDataFixture.selfUser
        )

        coreDataFixture.uiMOC.performGroupedBlockAndWait {
            // Create original message from self
            let originalMessage = try! conversation.appendText(content: "Original") as! ZMClientMessage
            originalMessage.sender = self.coreDataFixture.selfUser
            originalMessage.serverTimestamp = Date(timeIntervalSinceNow: -180)

            // Create reply from other user
            let replyMessage = try! conversation.appendText(
                content: "Reply",
                mentions: [],
                replyingTo: originalMessage,
                fetchLinkPreview: false,
                nonce: UUID()
            ) as! ZMClientMessage
            replyMessage.sender = self.coreDataFixture.otherUser
            replyMessage.serverTimestamp = Date()
            conversation.updateTimestampsAfterUpdatingMessage(replyMessage)
            conversation.lastReadServerTimeStamp = Date(timeIntervalSinceNow: -60)
            conversation.needsToCalculateUnreadMessages = true
            ZMConversation.calculateLastUnreadMessages(in: self.coreDataFixture.uiMOC)
        }

        return conversation
    }

    private func createConversationWithoutUnread() -> ZMConversation {
        let conversation = ZMConversation.createTeamGroupConversation(
            moc: coreDataFixture.uiMOC,
            otherUser: coreDataFixture.otherUser,
            selfUser: coreDataFixture.selfUser
        )

        coreDataFixture.uiMOC.performGroupedBlockAndWait {
            let message = try! conversation.appendText(content: "Read message") as! ZMClientMessage
            message.serverTimestamp = Date(timeIntervalSinceNow: -120)
            conversation.updateTimestampsAfterUpdatingMessage(message)
            conversation.lastReadServerTimeStamp = Date()
            conversation.needsToCalculateUnreadMessages = true
            ZMConversation.calculateLastUnreadMessages(in: self.coreDataFixture.uiMOC)
        }

        return conversation
    }
}
