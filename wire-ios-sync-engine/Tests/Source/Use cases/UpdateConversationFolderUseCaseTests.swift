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
        let (folderID, conversationID) = try await managedObjectContext.perform { [self] in
            let folder = modelHelper.createFolder(in: managedObjectContext)
            let conversation = modelHelper.createGroupConversation(in: managedObjectContext)

            guard let folderID = folder.remoteIdentifier,
                  let conversationID = conversation.remoteIdentifier else {
                XCTFail("Failed to create test objects with valid IDs")
                throw TestError.setupFailed
            }

            return (folderID, conversationID)
        }

        // WHEN
        try await sut.invoke(conversationID: conversationID, folderID: folderID)

        // THEN
        let updatedFolderID = await managedObjectContext.perform { [self] in
            ZMConversation.fetch(with: conversationID, in: managedObjectContext)?
                .folder?.remoteIdentifier
        }

        XCTAssertEqual(updatedFolderID, folderID)
    }

    private enum TestError: Error {
        case setupFailed
    }
}
