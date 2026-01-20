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

final class ConversationFilterSelectorTests: XCTestCase {

    private var sut: ConversationFilterSelector!
    private var conversationDirectory: MockConversationDirectory!
    private var conversationFilter: ConversationFilter?
    private var conversationFilterDidChange: Bool!

    @MainActor
    override func setUpWithError() throws {
        conversationDirectory = MockConversationDirectory()
        sut = ConversationFilterSelector(
            conversationFilter: { [unowned self] in conversationFilter },
            updateConversationFilter: { [unowned self] newValue in
                conversationFilter = newValue
                conversationFilterDidChange = true
            }
        )
        conversationFilterDidChange = false
    }

    @MainActor
    override func tearDownWithError() throws {
        conversationDirectory = nil
        sut = nil
        conversationFilterDidChange = nil
    }

    @MainActor
    func testConversationDirectoryDidChange_whenFolderFilterSelected() throws {
        // GIVEN
        let folderA = MockLabel(remoteIdentifier: UUID())
        let folderB = MockLabel(remoteIdentifier: UUID())

        conversationFilter = .folder(id: folderA.remoteIdentifier!, name: "folderName")

        // WHEN
        conversationDirectory.nonDeletedFolders = [folderA, folderB]
        sut.conversationDirectoryDidChange(conversationDirectory: conversationDirectory, changeInfo: .someValue)

        // THEN
        XCTAssertFalse(conversationFilterDidChange)
        XCTAssertEqual(conversationFilter, .folder(id: folderA.remoteIdentifier!, name: "folderName"))

        // WHEN
        conversationDirectory.nonDeletedFolders = [folderB]
        sut.conversationDirectoryDidChange(conversationDirectory: conversationDirectory, changeInfo: .someValue)

        // THEN
        XCTAssertTrue(conversationFilterDidChange)
        XCTAssertNil(conversationFilter)
    }

    @MainActor
    func testConversationDirectoryDidChange_whenNotFolderFilterSelected() throws {
        let testCases: [ConversationFilter?] = [
            .favorites,
            .groups,
            .oneOnOne,
            .channels,
            .unread,
            .mentions,
            .replies,
            .drafts,
            .none
        ]

        for testCase in testCases {
            // GIVEN
            conversationFilter = testCase

            // WHEN
            sut.conversationDirectoryDidChange(conversationDirectory: conversationDirectory, changeInfo: .someValue)

            // THEN
            XCTAssertFalse(conversationFilterDidChange)
        }
    }

}

private extension ConversationDirectoryChangeInfo {
    static let someValue = ConversationDirectoryChangeInfo(
        reloaded: false,
        updatedLists: [],
        updatedFolders: false
    )
}
