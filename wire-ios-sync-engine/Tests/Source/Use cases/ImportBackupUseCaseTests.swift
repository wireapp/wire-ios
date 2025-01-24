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

    private var coreDataStack: CoreDataStack!
    private var mockStreamDecryptor: MockImportBackupStreamDecryptorProtocol!
    private var mockFileArchiver: MockImportBackupFileArchiverProtocol!
    private var mockEntityStorage: MockImportBackupEntityStorageProtocol!
    private var mockAppStateUpdater: MockImportBackupAppStateUpdaterProtocol!
    private var dispatchGroup: ZMSDispatchGroup!
    private var sharedContainerURL: URL!
    private var mockUserSession: MockUserSession!
    private var sut: ImportBackupUseCase!

    override func setUp() async throws {
        let fileManager = FileManager()

        coreDataStack = try await CoreDataStackHelper()
            .createStack(inMemoryStore: true)

        mockStreamDecryptor = .init()
        mockStreamDecryptor.decryptInputOutputAccountIDPassword_MockMethod = { _, _, _, _ in }

        mockFileArchiver = .init()
        mockFileArchiver.unzipFileAtTo_MockMethod = { _, _ in }

        mockEntityStorage = .init()
        mockEntityStorage.importsDirectory = fileManager
            .temporaryDirectory
            .appending(path: UUID().uuidString)
        mockEntityStorage.createContextProviderAccountApplicationContainerDispatchGroup_MockMethod = { _, _, _ in
            try await CoreDataStackHelper()
                .createStack(inMemoryStore: true)
        }
        mockEntityStorage
            .replacePersistentStoreAccountIdentifierFromApplicationContainerDispatchGroup_MockMethod = { _, _, _, _ in
                URL(filePath: "/accountDataFolder/")
            }

        mockAppStateUpdater = .init()
        mockAppStateUpdater.reportImportProgressProgress_MockMethod = { _ in }
        mockAppStateUpdater.reportMigrationNeeded_MockMethod = {
            self.coreDataStack = nil
        }
        mockAppStateUpdater.selectAccountAndTriggerSlowSync_MockMethod = { _ in }

        dispatchGroup = .init(label: UUID().uuidString)

        sharedContainerURL = fileManager
            .temporaryDirectory
            .appending(path: UUID().uuidString)

        mockUserSession = .init()
        mockUserSession.contextProvider = coreDataStack
        await coreDataStack.viewContext.perform {
            self.mockUserSession.selfUserClient = .init(context: self.coreDataStack.viewContext)
        }

        sut = .init(
            userSession: { [weak self] in self?.mockUserSession },
            dispatchGroup: dispatchGroup,
            streamDecryptor: mockStreamDecryptor,
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
        dispatchGroup = nil
        mockAppStateUpdater = nil
        mockEntityStorage = nil
        mockFileArchiver = nil
        mockStreamDecryptor = nil
        coreDataStack = nil
    }

    func testFileExtensionsAreAccepted() async throws {
        // Given
        let extensions = ["ios_Wbu", "ioS-wbu"]
        mockUserSession = nil // expect `BackupRestoreError.noActiveAccount`

        for extensions in extensions {
            do {
                // When
                let filePath = "/path/to/file.\(extensions)"
                try await sut.invoke(url: URL(fileURLWithPath: filePath), password: "")
                XCTFail("Unexpected success")
            } catch BackupRestoreError.noActiveAccount {
                // Then
            }
        }
    }

    func testUnknownFileExtensionsThrow() async throws {
        // Given
        let extensions = ["zip"]
        mockUserSession = nil

        for extensions in extensions {
            do {
                // When
                let filePath = "/path/to/file.\(extensions)"
                try await sut.invoke(url: URL(fileURLWithPath: filePath), password: "")
                XCTFail("Unexpected success")
            } catch BackupRestoreError.invalidFileExtension {
                // Then
            }
        }
    }

    func testDecryptorIsCalledCorrectly() async throws {
        // Given
        let url = URL(fileURLWithPath: "backup.ios_wbu")
        let accountID = coreDataStack.account.userIdentifier

        // When
        try await sut.invoke(url: url, password: "c<%I2f41\"6!'")

        // Then
        XCTAssertFalse(mockAppStateUpdater.reportImportProgressProgress_Invocations.isEmpty)
        XCTAssertEqual(mockStreamDecryptor.decryptInputOutputAccountIDPassword_Invocations.first?.accountID, accountID)
        XCTAssertEqual(
            mockStreamDecryptor.decryptInputOutputAccountIDPassword_Invocations.first?.password,
            "c<%I2f41\"6!'"
        )
    }

}
