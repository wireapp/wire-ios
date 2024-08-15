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

import DifferenceKit
import XCTest

@testable import Wire

final class MockConversationListViewModelDelegate: NSObject, ConversationListViewModelDelegate {
    func listViewModel(_ model: ConversationListViewModel?, didUpdateSection section: Int) {
        // no-op
    }

    func listViewModel(_ model: ConversationListViewModel?, didUpdateSectionForReload section: Int, animated: Bool) {
        // no-op
    }

    func listViewModel(_ model: ConversationListViewModel?, didChangeFolderEnabled folderEnabled: Bool) {
        // no-op
    }

    func reload<C>(
        using stagedChangeset: StagedChangeset<C>,
        interrupt: ((Changeset<C>) -> Bool)?,
        setData: (C?) -> Void
    ) {
        setData(stagedChangeset.first?.data)
    }

    func listViewModelShouldBeReloaded() {
        // no-op
    }

    func listViewModel(_ model: ConversationListViewModel?, didSelectItem item: ConversationListItem?) {
        // no-op
    }
}

final class ConversationListViewModelTests: XCTestCase {

    var sut: ConversationListViewModel!
    var mockUserSession: UserSessionMock!
    var mockConversationListViewModelDelegate: MockConversationListViewModelDelegate!
    var mockConversation: ZMConversation!
    var coreDataFixture: CoreDataFixture!

    // Constants for section indices
    let sectionGroups = 0

    override func setUp() {
        super.setUp()

        removeViewModelState()
        mockUserSession = UserSessionMock()
        sut = ConversationListViewModel(userSession: mockUserSession)

        mockConversationListViewModelDelegate = MockConversationListViewModelDelegate()
        sut.delegate = mockConversationListViewModelDelegate

        coreDataFixture = CoreDataFixture()
        mockConversation = ZMConversation.createOtherUserConversation(moc: coreDataFixture.uiMOC, otherUser: coreDataFixture.otherUser)
    }

    override func tearDown() {
        sut = nil
        mockUserSession = nil
        mockConversationListViewModelDelegate = nil
        mockConversation = nil
        coreDataFixture = nil

        super.tearDown()
    }

    func removeViewModelState() {
        guard let persistentURL = ConversationListViewModel.persistentURL else { return }

        try? FileManager.default.removeItem(at: persistentURL)
    }

    // 2 group conversations and 1 contact. First group conversation is mock conversation
    func fillDummyConversations(mockConversation: ZMConversation) {
        let info = ConversationDirectoryChangeInfo(reloaded: false, updatedLists: [.groups, .contacts], updatedFolders: false)

        let teamConversation = ZMConversation.createTeamGroupConversation(moc: coreDataFixture.uiMOC,
                                                                          otherUser: coreDataFixture.otherUser,
                                                                          selfUser: coreDataFixture.selfUser)
        let oneToOneConversation = ZMConversation.createOtherUserConversation(moc: coreDataFixture.uiMOC,
                                                                              otherUser: coreDataFixture.otherUser)
        mockUserSession.mockConversationDirectory.mockGroupConversations = [mockConversation, teamConversation]
        mockUserSession.mockConversationDirectory.mockContactsConversations = [oneToOneConversation]

        sut.conversationDirectoryDidChange(info)
    }

    func testForNumberOfItems() {

        // GIVEN
        // Set the filter to a state that will include the mockConversation
        sut.selectedFilter = .groups

        fillDummyConversations(mockConversation: mockConversation)

        // WHEN & THEN
        XCTAssertEqual(sut.numberOfItems(inSection: sectionGroups), 2)
        XCTAssertEqual(sut.numberOfItems(inSection: 100), 0)
    }

    func testForIndexPathOfItemAndItemForIndexPath() {
        // GIVEN
        // Set the filter to a state that will include the mockConversation
        sut.selectedFilter = .groups

        fillDummyConversations(mockConversation: mockConversation)

        // WHEN
        guard let indexPath = sut.indexPath(for: mockConversation) else { XCTFail("indexPath is nil ")
            return
        }

        let item = sut.item(for: indexPath)

        // THEN
        XCTAssertEqual(item as? AnyHashable, mockConversation)
    }

    func testThatOutOfBoundIndexPathReturnsNilItem() {
        // GIVEN & WHEN
        fillDummyConversations(mockConversation: mockConversation)

        // THEN
        XCTAssertNil(sut.item(for: IndexPath(item: 1000, section: 1000)))
    }

    func testThatNonExistConversationHasNilIndexPath() {
        // GIVEN, WHEN && THEN
        XCTAssertNil(sut.indexPath(for: ZMConversation()))
    }

    func testForSectionCount() {
        // GIVEN
        // Set the filter to a state that will include the mockConversation
        sut.selectedFilter = .groups

        // THEN
        XCTAssertEqual(sut.sectionCount, 1)
    }

    func testForSectionAtIndex() {
        // GIVEN
        // Set the filter to a state that will include the mockConversation
        sut.selectedFilter = .groups

        fillDummyConversations(mockConversation: mockConversation)

        // WHEN
        guard let sectionItems = sut.section(at: sectionGroups) else {
            XCTFail("Section at index \(sectionGroups) is nil")
            return
        }

        // THEN
        let containsMockConversation = sectionItems.contains {
            guard let conversation = $0 as? ZMConversation else { return false }
            return conversation.remoteIdentifier == mockConversation.remoteIdentifier
        }
        XCTAssertTrue(containsMockConversation, "Section does not contain the mock conversation")
        XCTAssertNil(sut.section(at: 100))
    }

    func testForSelectItem() {
        // GIVEN
        // Set the filter to a state that will include the mockConversation
        sut.selectedFilter = .groups

        fillDummyConversations(mockConversation: mockConversation)

        // WHEN & THEN
        XCTAssert(sut.select(itemToSelect: mockConversation))
        XCTAssertEqual(sut.selectedItem as? AnyHashable, mockConversation)
    }
}
