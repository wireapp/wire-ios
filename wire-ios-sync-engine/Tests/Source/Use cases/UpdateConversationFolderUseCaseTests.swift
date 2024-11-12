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

final class UpdateConversationFolderUseCaseTests: XCTestCase {

    // MARK: - Properties

    private let coreDataStackHelper = CoreDataStackHelper()
    private var stack: CoreDataStack!
    private let modelHelper = ModelHelper()
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

    func testInvoke_ShouldMoveConversationToSpecifiedFolder() async throws {
        // GIVEN
        var folderID: UUID!
        var conversationID: UUID!

        managedObjectContext.performAndWait {
            let folder = modelHelper.createFolder(in: managedObjectContext)
            let conversation = modelHelper.createGroupConversation(in: managedObjectContext)
            folderID = folder.remoteIdentifier
            conversationID = conversation.remoteIdentifier
        }

        folderID = try XCTUnwrap(folderID)
        conversationID = try XCTUnwrap(conversationID)

        // WHEN
        try await sut.invoke(conversationID: conversationID, folderID: folderID)

        // THEN
        var updatedFolderID: UUID?
        managedObjectContext.performAndWait {
            if let conversation = ZMConversation.fetch(with: conversationID, in: managedObjectContext) {
                updatedFolderID = conversation.folder?.remoteIdentifier
            }
        }

        XCTAssertEqual(updatedFolderID, folderID)
    }
}
