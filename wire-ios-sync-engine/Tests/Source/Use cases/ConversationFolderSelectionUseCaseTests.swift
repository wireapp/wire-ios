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

import WireDataModelSupport
import XCTest

@testable import WireSyncEngine

final class ConversationFolderSelectionUseCaseTests: XCTestCase {

    // MARK: - Properties

    private let coreDataStackHelper = CoreDataStackHelper()
    private var stack: CoreDataStack!
    private var sut: UpdateConversationFolderUseCase!

    private var managedObjectContext: NSManagedObjectContext {
        return stack.syncContext
    }

    // MARK: - setUp

    override func setUp() async throws {
        stack = try await coreDataStackHelper.createStack()
        sut = UpdateConversationFolderUseCase(context: managedObjectContext)
    }

    // MARK: - tearDown

    override func tearDown() async throws {
        stack = nil
        sut = nil
        try coreDataStackHelper.cleanupDirectory()
    }
    // MARK: - Tests

    func testInvoke_ShouldMoveConversationToSpecifiedFolder() throws {
        // GIVEN
        let conversationID = UUID()
        let folderID = UUID()
        let folder = Label.insertNewObject(in: managedObjectContext)
        folder.remoteIdentifier = folderID
        folder.name = "Test Folder"
        folder.kind = .folder

        let conversation = ZMConversation.insertNewObject(in: managedObjectContext)
        conversation.remoteIdentifier = conversationID

        try managedObjectContext.save()

        // WHEN
        try sut.invoke(conversationID: conversationID, folderID: folderID)

        // THEN
        XCTAssertEqual(conversation.folder?.remoteIdentifier, folderID)
    }
}
