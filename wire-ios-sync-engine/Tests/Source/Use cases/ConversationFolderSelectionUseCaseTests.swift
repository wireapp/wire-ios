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

@testable import WireSyncEngine

final class ConversationFolderSelectionUseCaseTests: XCTestCase {

    // MARK: - Properties

    private var mockConversation: MockToFolderMovableConversation!
    private var sut: ConversationFolderSelectionUseCase!

    // MARK: - setUp

    override func setUp() {
        mockConversation = .init()
        sut = ConversationFolderSelectionUseCase()
    }

    // MARK: - tearDown

    override func tearDown() {
        mockConversation = nil
        sut = nil
    }

    // MARK: - Tests

    func testInvoke_ShouldMoveConversationToSpecifiedFolder() {
        // GIVEN
        let expectedFolder = MockLabelType(kind: .folder, name: "Test Folder")
        mockConversation.moveToFolder_MockMethod = { _ in }

        // WHEN
        sut.invoke(folder: expectedFolder, conversation: mockConversation)

        // THEN
        XCTAssertEqual(mockConversation.moveToFolder_Invocations.count, 1)
        XCTAssertEqual(mockConversation.moveToFolder_Invocations.first?.kind, expectedFolder.kind)
        XCTAssertEqual(mockConversation.moveToFolder_Invocations.first?.name, expectedFolder.name)
    }

}
