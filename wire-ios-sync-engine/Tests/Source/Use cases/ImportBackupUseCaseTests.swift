//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
import WireDataModelSupport

@testable import WireSyncEngine
@testable import WireSyncEngineSupport

final class ImportBackupUseCaseTests: XCTestCase {

    private var mockFileArchiver: MockImportBackupFileArchiverProtocol!
    private var mockEntityStorage: MockImportBackupEntityStorageProtocol!
    private var mockAppStateUpdater: MockImportBackupAppStateUpdaterProtocol!
    private var dispatchGroup: ZMSDispatchGroup!
    private var sharedContainerURL: URL!
    private var coreDataStack: CoreDataStack!
    private var mockUserSession: MockUserSession!
    private var sut: ImportBackupUseCase!

    override func setUp() async throws {

        mockFileArchiver = .init()

        mockEntityStorage = .init()

        mockAppStateUpdater = .init()

        dispatchGroup = .init(label: UUID().uuidString)

        sharedContainerURL = FileManager()
            .temporaryDirectory
            .appending(path: UUID().uuidString)

        coreDataStack = try await CoreDataStackHelper()
            .createStack(inMemoryStore: true)

        sut = .init(
            userSession: { [weak self] in self?.mockUserSession },
            dispatchGroup: dispatchGroup,
            fileArchiver: mockFileArchiver,
            entityStorage: mockEntityStorage,
            appStateUpdater: mockAppStateUpdater,
            sharedContainerURL: sharedContainerURL,
            logger: .init(tag: "mock")
        )
    }

    override func tearDownWithError() throws {
        sut = nil
        mockUserSession = nil
        coreDataStack = nil
        dispatchGroup = nil
        mockAppStateUpdater = nil
        mockEntityStorage = nil
        mockFileArchiver = nil
    }

    func testExample() throws {
        XCTFail("TODO: create test")
    }

}
