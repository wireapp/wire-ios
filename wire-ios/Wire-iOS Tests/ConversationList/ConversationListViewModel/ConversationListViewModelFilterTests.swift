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

import WireDataModel
import XCTest

@testable import Wire

final class ConversationListViewModelFilterTests: XCTestCase {

    var sut: ConversationListViewModel!
    var mockUserSession: UserSessionMock!
    var coreDataFixture: CoreDataFixture!

    override func setUp() async throws {
        try await super.setUp()

        coreDataFixture = try await CoreDataFixture()
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

    func testUnreadFilter_UsesUnreadConversationListType() {
        // GIVEN
        sut.selectedFilter = .unread

        // WHEN
        let sections = sut.createSections()

        // THEN
        XCTAssertEqual(sections.count, 1)
        XCTAssertEqual(sections.first?.kind, .conversations)
    }

    func testUnreadFilter_ShowsOnlyConversationsSection() {
        // GIVEN
        sut.selectedFilter = .unread

        // WHEN
        let sections = sut.createSections()

        // THEN
        XCTAssertEqual(sections.count, 1)
        XCTAssertEqual(sections.first?.kind, .conversations)
    }

    // MARK: - Mentions Filter Tests

    func testMentionsFilter_UsesMentionsConversationListType() {
        // GIVEN
        sut.selectedFilter = .mentions

        // WHEN
        let sections = sut.createSections()

        // THEN
        XCTAssertEqual(sections.count, 1)
        XCTAssertEqual(sections.first?.kind, .conversations)
    }

    func testMentionsFilter_ShowsOnlyConversationsSection() {
        // GIVEN
        sut.selectedFilter = .mentions

        // WHEN
        let sections = sut.createSections()

        // THEN
        XCTAssertEqual(sections.count, 1)
        XCTAssertEqual(sections.first?.kind, .conversations)
    }

    // MARK: - Replies Filter Tests

    func testRepliesFilter_UsesRepliesConversationListType() {
        // GIVEN
        sut.selectedFilter = .replies

        // WHEN
        let sections = sut.createSections()

        // THEN
        XCTAssertEqual(sections.count, 1)
        XCTAssertEqual(sections.first?.kind, .conversations)
    }

    func testRepliesFilter_ShowsOnlyConversationsSection() {
        // GIVEN
        sut.selectedFilter = .replies

        // WHEN
        let sections = sut.createSections()

        // THEN
        XCTAssertEqual(sections.count, 1)
        XCTAssertEqual(sections.first?.kind, .conversations)
    }

    // MARK: - Drafts Filter Tests

    func testDraftsFilter_UsesDraftsConversationListType() {
        // GIVEN
        sut.selectedFilter = .drafts

        // WHEN
        let sections = sut.createSections()

        // THEN
        XCTAssertEqual(sections.count, 1)
        XCTAssertEqual(sections.first?.kind, .conversations)
    }

    func testDraftsFilter_ShowsOnlyConversationsSection() {
        // GIVEN
        sut.selectedFilter = .drafts

        // WHEN
        let sections = sut.createSections()

        // THEN
        XCTAssertEqual(sections.count, 1)
        XCTAssertEqual(sections.first?.kind, .conversations)
    }

    // MARK: - No Filter Tests

    func testNoFilter_ShowsContactRequestsAndConversations() {
        // GIVEN
        sut.selectedFilter = nil

        // WHEN
        let sections = sut.createSections()

        // THEN
        XCTAssertEqual(sections.count, 2)
        XCTAssertEqual(sections[0].kind, .contactRequests)
        XCTAssertEqual(sections[1].kind, .conversations)
    }

    func testOtherFilters_ShowCorrectSections() {
        // Test Groups Filter
        sut.selectedFilter = .groups
        var sections = sut.createSections()
        XCTAssertEqual(sections.count, 1)
        XCTAssertEqual(sections.first?.kind, .groups)

        // Test Favorites Filter
        sut.selectedFilter = .favorites
        sections = sut.createSections()
        XCTAssertEqual(sections.count, 1)
        XCTAssertEqual(sections.first?.kind, .favorites)

        // Test Drafts Filter
        sut.selectedFilter = .drafts
        sections = sut.createSections()
        XCTAssertEqual(sections.count, 1)
        XCTAssertEqual(sections.first?.kind, .conversations)
    }
}
