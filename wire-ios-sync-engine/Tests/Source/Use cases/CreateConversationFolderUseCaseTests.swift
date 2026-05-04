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

import WireDataModelSupport
import XCTest

@testable import WireSyncEngine

final class CreateConversationFolderUseCaseTests: XCTestCase {

    // MARK: - Properties

    private let coreDataStackHelper = CoreDataStackHelper()
    private var stack: CoreDataStack!
    private var sut: CreateConversationFolderUseCase!

    private var context: NSManagedObjectContext {
        stack.syncContext
    }

    // MARK: - setUp

    override func setUp() async throws {
        stack = try await coreDataStackHelper.createStack()
        sut = CreateConversationFolderUseCase(context: context)
    }

    // MARK: - tearDown

    override func tearDown() async throws {
        stack = nil
        sut = nil
        try coreDataStackHelper.cleanupDirectory()
    }

    // MARK: - Unit Tests

    func testInvoke_createsFolderWithName() async throws {
        // GIVEN
        let folderName = "Test Folder"

        // WHEN
        let label = try await sut.invoke(with: folderName)

        // THEN
        await context.perform {
            XCTAssertNotNil(label, "Expected a non-nil LabelType for the first folder")
            XCTAssertEqual(label?.name, folderName, "Label name should match the given folder name")
            XCTAssertEqual(label?.kind, .folder, "Label kind should be set to folder")
        }
    }

    func testInvoke_createsUniqueFolderWithEachCall() async throws {
        // GIVEN
        let firstFolderName = "Folder 1"
        let secondFolderName = "Folder 2"

        // WHEN
        let firstLabel = try await sut.invoke(with: firstFolderName)
        let secondLabel = try await sut.invoke(with: secondFolderName)

        // THEN
        await context.perform {
            XCTAssertNotNil(firstLabel, "Expected a non-nil LabelType for the first folder")
            XCTAssertNotNil(secondLabel, "Expected a non-nil LabelType for the second folder")
            XCTAssertNotEqual(
                firstLabel?.remoteIdentifier,
                secondLabel?.remoteIdentifier,
                "Each folder should have a unique identifier"
            )
        }
    }
}
