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

import XCTest

@testable import WireDataModelSupport
@testable import WireSyncEngine

class ShareFileUseCaseTests: ZMTBaseTest {

    // MARK: - Properties

    private var sut: ShareFileUseCase!
    private var coreDataStackHelper: CoreDataStackHelper!
    private var coreDataStack: CoreDataStack!

    // MARK: - Life cycle

    override func setUp() async throws {
        try await super.setUp()

        coreDataStackHelper = CoreDataStackHelper()
        coreDataStack = try await coreDataStackHelper.createStack()

        await coreDataStack.viewContext.perform {
            self.coreDataStack.viewContext.zm_fileAssetCache = FileAssetCache(location: .cachesDirectory)
        }

        sut = ShareFileUseCase(contextProvider: coreDataStack)
    }

    override func tearDown() {
        try? coreDataStack.viewContext.zm_fileAssetCache.wipeCaches()
        coreDataStack = nil
        coreDataStackHelper = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Tests

    func testInvoke_SharesFileInGivenConversations() throws {
        // Given
        let conversation1 = createConversation()
        let conversation2 = createConversation()

        let url = try XCTUnwrap(createTemporaryFile())
        let metadata = ZMFileMetadata(fileURL: url)

        // When
        sut.invoke(
            fileMetadata: metadata,
            conversations: [conversation1, conversation2]
        )

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Then
        XCTAssertNotNil(conversation1.lastMessage)
        XCTAssertNotNil(conversation2.lastMessage)

        XCTAssertEqual(conversation1.lastMessage?.fileMessageData?.filename, metadata.filename)
        XCTAssertEqual(conversation2.lastMessage?.fileMessageData?.filename, metadata.filename)

        try deleteTemporaryFile(at: url)
    }

    // MARK: - Helpers

    private func createTemporaryFile() -> URL? {
        let tempDirectoryURL = FileManager.default.temporaryDirectory
        let fileName = UUID().uuidString
        let fileURL = tempDirectoryURL.appendingPathComponent(fileName)

        FileManager.default.createFile(atPath: fileURL.path, contents: nil, attributes: nil)

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }

        return fileURL
    }

    private func deleteTemporaryFile(at url: URL) throws {
        try FileManager.default.removeItem(at: url)
    }

    private func createConversation() -> ZMConversation {
        let context = coreDataStack.viewContext

        let conversation = ZMConversation.insertNewObject(in: context)
        conversation.isArchived = false
        conversation.messageProtocol = .proteus
        conversation.conversationType = .group

        return conversation
    }
}
