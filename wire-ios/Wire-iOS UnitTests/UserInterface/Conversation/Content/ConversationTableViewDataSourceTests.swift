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

import UIKit
import WireDataModel
import XCTest

@testable import Wire

final class ConversationTableViewDataSourceTests: XCTestCase, CoreDataFixtureTestHelper {

    var coreDataFixture: CoreDataFixture!
    private var sut: ConversationTableViewDataSource!
    private var conversation: ZMConversation!
    private var userSession: UserSessionMock!
    private var tableView: UpsideDownTableView!
    private var previousDisableLinkPreviews = false

    @MainActor
    override func setUp() async throws {
        coreDataFixture = try await CoreDataFixture()
        previousDisableLinkPreviews = Settings.disableLinkPreviews
        // UserSessionMock executes enqueued work inline, so skip background link-preview refetching.
        Settings.disableLinkPreviews = true
        conversation = createGroupConversation()
        userSession = UserSessionMock(
            selfUser: selfUser,
            selfUserLegalHoldSubject: selfUser,
            editableSelfUser: selfUser
        )
        userSession.coreDataStack = coreDataFixture.coreDataStack
        tableView = UpsideDownTableView(frame: .zero, style: .plain)
        let delegate = CellDelegateStub()
        sut = ConversationTableViewDataSource(
            conversation: conversation,
            tableView: tableView,
            actionResponder: delegate,
            cellDelegate: delegate,
            userSession: userSession,
            getUserByIDUseCase: GetUserByIdUseCase(),
            wireMessagingFactory: MockWireMessagingFactoryProtocol(),
            conversationCellProvider: MockConversationCellProviderProtocol()
        )
    }

    override func tearDown() {
        Settings.disableLinkPreviews = previousDisableLinkPreviews
        sut = nil
        tableView = nil
        userSession = nil
        conversation = nil
        coreDataFixture = nil
        super.tearDown()
    }

    @MainActor
    func testEmptyConversationShowsOnlyOfflineNoticeWithStableIdentity() async throws {
        sut.showsOfflineNotice = true
        let sections = await calculateSections()
        let section = try XCTUnwrap(sections.first)
        let notice = try XCTUnwrap(section.elements.first)

        XCTAssertEqual(sections.count, 1)
        XCTAssertEqual(section.elements.count, 1)
        XCTAssertTrue(notice.instance is ConversationOfflineNoticeCellDescription)
        XCTAssertNil(notice.message)
        XCTAssertNil(notice.actionController)
        let rebuiltSections = await calculateSections()
        XCTAssertEqual(rebuiltSections.first?.model, section.model)
        XCTAssertEqual(rebuiltSections.first?.elements.first?.differenceIdentifier, notice.differenceIdentifier)

        sut.reloadSections(newSections: sections, animated: false)
        let indexPath = IndexPath(row: 0, section: 0)
        let cell = sut.tableView(tableView, cellForRowAt: indexPath)
        XCTAssertEqual(cell.accessibilityIdentifier, "offline_notice")
        sut.select(indexPath: indexPath)
        sut.deselect(indexPath: indexPath)

        sut.showsOfflineNotice = false
        XCTAssertTrue(sut.currentSections.isEmpty)
    }

    @MainActor
    func testEmptyConversationDoesNotShowNoticeWhenDisabled() async {
        let sections = await calculateSections()
        XCTAssertTrue(sections.isEmpty)
    }

    @MainActor
    func testNoticeMovesAbovePendingMessagesAndBackToEmptyState() async throws {
        sut.showsOfflineNotice = true
        for index in 0 ..< 3 {
            let message = try conversation.appendText(content: "Pending \(index)")
            (message as? ZMMessage)?.serverTimestamp = Date(timeIntervalSince1970: Double(index + 1))
        }
        try coreDataFixture.uiMOC.save()
        await loadMessages()

        XCTAssertEqual(sut.currentSections.count, 3)
        XCTAssertEqual(noticeSectionIndices(), [2])
        let oldestSection = try XCTUnwrap(sut.currentSections.last)
        XCTAssertTrue(oldestSection.elements.last?.instance is ConversationOfflineNoticeCellDescription)

        for message in sut.allMessages {
            coreDataFixture.uiMOC.delete(message)
        }
        try coreDataFixture.uiMOC.save()
        await loadMessages()

        XCTAssertEqual(sut.currentSections.count, 1)
        XCTAssertEqual(sut.currentSections.first?.elements.count, 1)
        XCTAssertEqual(noticeSectionIndices(), [0])
    }

    @MainActor
    func testNoticeIsBelowNewestSentMessage() async throws {
        sut.showsOfflineNotice = true
        let message = try XCTUnwrap(try conversation.appendText(content: "Sent") as? ZMMessage)
        message.markAsSent()
        try coreDataFixture.uiMOC.save()
        await loadMessages()

        XCTAssertEqual(noticeSectionIndices(), [0])
        XCTAssertTrue(sut.currentSections.first?.elements.first?.instance is ConversationOfflineNoticeCellDescription)
    }

    @MainActor
    func testNoticeSeparatesPendingMessagesFromSentHistoryAfterRebuild() async throws {
        sut.showsOfflineNotice = true
        let sentMessage = try XCTUnwrap(try conversation.appendText(content: "Sent") as? ZMMessage)
        sentMessage.serverTimestamp = Date(timeIntervalSince1970: 1)
        sentMessage.markAsSent()
        let pendingMessage = try XCTUnwrap(try conversation.appendText(content: "Pending") as? ZMMessage)
        pendingMessage.serverTimestamp = Date(timeIntervalSince1970: 2)
        try coreDataFixture.uiMOC.save()
        await loadMessages()

        XCTAssertEqual(sut.currentSections.count, 2)
        XCTAssertEqual(noticeSectionIndices(), [0])
        XCTAssertTrue(sut.currentSections.first?.elements.last?.instance is ConversationOfflineNoticeCellDescription)

        let rebuiltSections = await calculateSections()
        sut.reloadSections(newSections: rebuiltSections, animated: false)
        XCTAssertEqual(noticeSectionIndices(), [0])
        XCTAssertTrue(sut.currentSections.first?.elements.last?.instance is ConversationOfflineNoticeCellDescription)
    }

    @MainActor
    func testNoticeIsHiddenWhenNewerMessagesAreNotLoaded() async throws {
        sut.showsOfflineNotice = true
        let message = try XCTUnwrap(try conversation.appendText(content: "Newest") as? ZMMessage)
        message.markAsSent()
        try coreDataFixture.uiMOC.save()
        await loadMessages(offset: 1)

        XCTAssertTrue(sut.hasNewerMessagesToLoad)
        XCTAssertTrue(sut.currentSections.isEmpty)
    }

    @MainActor
    private func calculateSections() async -> [ConversationTableViewDataSource.Section] {
        await withCheckedContinuation { continuation in
            sut.calculateSections { continuation.resume(returning: $0) }
        }
    }

    @MainActor
    private func loadMessages(offset: Int = 0) async {
        await withCheckedContinuation { continuation in
            sut.loadMessages(offset: offset) { continuation.resume() }
        }
    }

    private func noticeSectionIndices() -> [Int] {
        sut.currentSections.indices.filter { index in
            sut.currentSections[index].elements.contains { $0.instance is ConversationOfflineNoticeCellDescription }
        }
    }
}

private final class CellDelegateStub: ConversationMessageCellDelegate {
    func conversationMessageCell(_ contentView: UIView, present viewController: UIViewController) {}

    func conversationMessageWantsToOpenUserDetails(
        _ cell: UIView,
        user: UserType,
        sourceView: UIView,
        frame: CGRect
    ) {}

    func conversationMessageWantsToOpenMessageDetails(
        _ cell: UIView,
        for message: ZMConversationMessage,
        preferredDisplayMode: MessageDetailsDisplayMode
    ) {}

    func conversationMessageWantsToOpenGuestOptionsFromView(_ cell: UIView, sourceView: UIView) {}

    func conversationMessageWantsToOpenParticipantsDetails(
        _ cell: UIView,
        selectedUsers: [UserType],
        sourceView: UIView
    ) {}

    func conversationMessageShouldUpdate() {}
    func conversationMessageContentDidChangeSize() {}
    func perform(action: MessageAction, for message: ZMConversationMessage, view: UIView) {}
}
