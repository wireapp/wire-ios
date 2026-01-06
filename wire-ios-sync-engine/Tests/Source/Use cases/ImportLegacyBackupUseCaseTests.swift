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
import WireDomainPackage
import WireFoundation
import WireUtilitiesPackageSupport
import XCTest

@testable import WireSyncEngine
@testable import WireSyncEngineSupport

final class ImportLegacyBackupUseCaseTests: XCTestCase {

    private var coreDataStack: CoreDataStack!
    private var mockStreamDecryptor: MockImportLegacyBackupStreamDecryptorProtocol!
    private var mockFileUnarchiver: FileUnarchiverProtocolMock!
    private var mockEntityStorage: MockImportBackupEntityStorageProtocol!
    private var mockAppStateUpdater: MockImportBackupAppStateUpdaterProtocol!
    private var dispatchGroup: ZMSDispatchGroup!
    private var sharedContainerURL: URL!
    private var mockUserSession: MockUserSession!
    private var sut: ImportLegacyBackupUseCase!

    override func setUp() async throws {
        let fileManager = FileManager()
        let selfUserQualifiedID = QualifiedID.random()

        coreDataStack = try await CoreDataStackHelper()
            .createStack(inMemoryStore: true)

        mockStreamDecryptor = .init()
        mockStreamDecryptor.decryptInputOutputAccountIDPassword_MockMethod = { _, _, _, _ in }

        mockFileUnarchiver = .init()
        mockFileUnarchiver.unzipFileAtSourceURLURLToDestinationURLURLVoidClosure = { _, _ in }

        mockEntityStorage = .init()
        mockEntityStorage.importsDirectory = fileManager
            .temporaryDirectory
            .appending(path: UUID().uuidString)

        mockEntityStorage
            .createContextProviderAccountApplicationContainerDispatchGroupLocalDomainIsFederationEnabled_MockMethod =
            { _, _, _, _, _ in
                // This closure is called after session tear down and the persistent store is replaced.
                // It is called to create a temporary stack and restore the user client backup.
                XCTAssertNil(self.coreDataStack)
                let stack = try await CoreDataStackHelper()
                    .createStack(inMemoryStore: true)
                try await stack.viewContext.perform {
                    let user = ZMUser.selfUser(in: stack.viewContext)
                    user.remoteIdentifier = selfUserQualifiedID.uuid
                    user.domain = selfUserQualifiedID.domain
                    try stack.viewContext.save()
                }
                self.coreDataStack = stack
                return stack
            }
        mockEntityStorage
            .replacePersistentStoreAccountIdentifierFromApplicationContainer_MockMethod = { _, _, _ in
                URL(filePath: "/accountDataFolder/")
            }

        mockAppStateUpdater = .init()
        mockAppStateUpdater.reportMigrationNeeded_MockMethod = {
            // This closure is called when the user session should be torn down and the core data stack closed.
            self.coreDataStack = nil
        }
        mockAppStateUpdater.selectAccountAndTriggerSlowSync_MockMethod = { _ in }

        dispatchGroup = .init(label: UUID().uuidString)

        sharedContainerURL = fileManager
            .temporaryDirectory
            .appending(path: UUID().uuidString)

        // setup self user and self user client
        let viewContext = coreDataStack.viewContext
        let selfUser = await viewContext.perform {
            let user = ZMUser.selfUser(in: viewContext)
            user.remoteIdentifier = selfUserQualifiedID.uuid
            user.domain = selfUserQualifiedID.domain
            return user
        }
        mockUserSession = .init()
        mockUserSession.contextProvider = coreDataStack
        mockUserSession.selfUser = selfUser
        try await viewContext.perform { [viewContext] in
            let selfUserClient = UserClient.insertNewSelfClient(
                in: viewContext,
                selfUser: selfUser,
                model: "some model",
                label: ""
            )
            selfUserClient.remoteIdentifier = UUID().uuidString
            selfUserClient.markAsSelfClient()
            self.mockUserSession.selfUserClient = selfUserClient
            try viewContext.save()
        }

        let backupFile = URL(fileURLWithPath: "backup.ios_wbu")
        sut = ImportLegacyBackupUseCase(
            url: backupFile,
            userSession: { [weak self] in self?.mockUserSession },
            dispatchGroup: dispatchGroup,
            streamDecryptor: mockStreamDecryptor,
            fileUnarchiver: mockFileUnarchiver,
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
        mockFileUnarchiver = nil
        mockStreamDecryptor = nil
        coreDataStack = nil
        sharedContainerURL = nil
    }

    func testMockInvocations() async throws {
        // Given
        let accountID = coreDataStack.account.userIdentifier

        // When
        let sequence = try await sut.invoke(password: "c<%I2f41\"6!'")
            .reduce(into: [ImportBackupProgress]()) { $0 += [$1] }

        // Then
        XCTAssertEqual(sequence, [.progress(1, 4), .progress(2, 4), .done])
        XCTAssertEqual(mockStreamDecryptor.decryptInputOutputAccountIDPassword_Invocations.first?.accountID, accountID)
        XCTAssertEqual(
            mockStreamDecryptor.decryptInputOutputAccountIDPassword_Invocations.first?.password,
            "c<%I2f41\"6!'"
        )
        XCTAssertFalse(
            mockFileUnarchiver.unzipFileAtSourceURLURLToDestinationURLURLVoidReceivedInvocations.isEmpty
        )
        XCTAssertFalse(mockAppStateUpdater.reportMigrationNeeded_Invocations.isEmpty)
        XCTAssertFalse(
            mockEntityStorage
                .replacePersistentStoreAccountIdentifierFromApplicationContainer_Invocations.isEmpty
        )
        XCTAssertFalse(mockAppStateUpdater.selectAccountAndTriggerSlowSync_Invocations.isEmpty)
        // ensure the user client was preserved
        let model = await coreDataStack.viewContext.perform {
            let selfClient = ZMUser.selfUser(in: self.coreDataStack.viewContext).selfClient()
            return selfClient?.model
        }
        XCTAssertEqual(model, "some model")
    }

}
