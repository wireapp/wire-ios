//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

final class LegacyNotificationServiceCryptoStackTest: XCTestCase {

    private var mockCryptoboxMigrator: MockCryptoboxMigrationManagerInterface!

    override func setUpWithError() throws {
        createCoreCryptoKeyIfNeeded()

        mockCryptoboxMigrator = MockCryptoboxMigrationManagerInterface()

        try super.setUpWithError()
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()

        mockCryptoboxMigrator = nil
    }

    // MARK: - Tests

    func test_CryptoStackSetup_OnInit_ProteusOnly() throws {
        // GIVEN
        let service = LegacyNotificationService()
        let configuration = LegacyNotificationService.CryptoSetupConfiguration(
            shouldSetupProteusService: true,
            shouldSetupMLSService: false
        )

        mockCryptoboxMigrator.isMigrationNeededAccountDirectory_MockValue = false
        mockCryptoboxMigrator.completeMigrationSyncContext_MockMethod = { _ in }

        let userIdentifier = UUID()
        let coreDataStack = try makeMockCoreDataStack(userIdentifier: userIdentifier)
        let context = coreDataStack.syncContext

        createSelfUserAndClient(accountIdentifier: userIdentifier, syncContext: context)

        XCTAssertNil(context.mlsService)
        XCTAssertNil(context.mlsEncryptionService)
        XCTAssertNil(context.mlsDecryptionService)
        XCTAssertNil(context.proteusService)
        XCTAssertNil(context.coreCrypto)

        // WHEN
        try service.setUpCoreCryptoStack(
            accountContainer: coreDataStack.accountContainer,
            applicationContainer: coreDataStack.applicationContainer,
            syncContext: coreDataStack.syncContext,
            cryptoboxMigrationManager: mockCryptoboxMigrator,
            setupConfiguration: configuration
        )

        // THEN
        XCTAssertNil(context.mlsService)
        XCTAssertNil(context.mlsEncryptionService)
        XCTAssertNil(context.mlsDecryptionService)
        XCTAssertNotNil(context.proteusService)
        XCTAssertNotNil(context.coreCrypto)
    }

    //    func test_CryptoStackSetup_OnInit_MLSOnly() throws {
    //        // GIVEN
    //        createCoreCryptoKeyIfNeeded()
    //        mlsFlag.isOn = true
    //
    //        let context = coreDataStack.syncContext
    //
    //        XCTAssertNil(context.mlsService)
    //        XCTAssertNil(context.mlsEncryptionService)
    //        XCTAssertNil(context.mlsDecryptionService)
    //        XCTAssertNil(context.proteusService)
    //        XCTAssertNil(context.coreCrypto)
    //
    //        // WHEN
    //        _ = createNotificationSession()
    //
    //        // THEN
    //        XCTAssertNil(context.mlsService)
    //        XCTAssertNil(context.mlsEncryptionService)
    //        XCTAssertNotNil(context.mlsDecryptionService)
    //        XCTAssertNil(context.proteusService)
    //        XCTAssertNotNil(context.coreCrypto)
    //    }
    //
    //    func test_CryptoStackSetup_DontSetupMLSIfAPIV5IsNotAvailable() throws {
    //        // GIVEN
    //        createCoreCryptoKeyIfNeeded()
    //        mlsFlag.isOn = true
    //        BackendInfo.apiVersion = .v1
    //
    //        let context = coreDataStack.syncContext
    //
    //        XCTAssertNil(context.mlsService)
    //        XCTAssertNil(context.mlsEncryptionService)
    //        XCTAssertNil(context.mlsDecryptionService)
    //        XCTAssertNil(context.proteusService)
    //        XCTAssertNil(context.coreCrypto)
    //
    //        // WHEN
    //        _ = createNotificationSession()
    //
    //        // THEN
    //        XCTAssertNil(context.mlsService)
    //        XCTAssertNil(context.mlsEncryptionService)
    //        XCTAssertNil(context.mlsDecryptionService)
    //        XCTAssertNil(context.proteusService)
    //        XCTAssertNil(context.coreCrypto)
    //    }
    //
    //    func test_CryptoStackSetup_OnInit_ProteusAndMLS() throws {
    //        // GIVEN
    //        createCoreCryptoKeyIfNeeded()
    //        proteusFlag.isOn = true
    //        mlsFlag.isOn = true
    //
    //        let context = coreDataStack.syncContext
    //
    //        XCTAssertNil(context.mlsService)
    //        XCTAssertNil(context.mlsEncryptionService)
    //        XCTAssertNil(context.mlsDecryptionService)
    //        XCTAssertNil(context.proteusService)
    //        XCTAssertNil(context.coreCrypto)
    //
    //        // WHEN
    //        _ = createNotificationSession()
    //
    //        // THEN
    //        XCTAssertNil(context.mlsService)
    //        XCTAssertNil(context.mlsEncryptionService)
    //        XCTAssertNotNil(context.mlsDecryptionService)
    //        XCTAssertNotNil(context.proteusService)
    //        XCTAssertNotNil(context.coreCrypto)
    //    }
    //
    //    func test_CryptoStackSetup_OnInit_AllFlagsDisabled() throws {
    //        // GIVEN
    //        createCoreCryptoKeyIfNeeded()
    //        XCTAssertFalse(proteusFlag.isOn)
    //        XCTAssertFalse(mlsFlag.isOn)
    //
    //        let context = coreDataStack.syncContext
    //
    //        XCTAssertNil(context.mlsService)
    //        XCTAssertNil(context.mlsEncryptionService)
    //        XCTAssertNil(context.mlsDecryptionService)
    //        XCTAssertNil(context.proteusService)
    //        XCTAssertNil(context.coreCrypto)
    //
    //        // WHEN
    //        _ = createNotificationSession()
    //
    //        // THEN
    //        XCTAssertNil(context.mlsService)
    //        XCTAssertNil(context.mlsEncryptionService)
    //        XCTAssertNil(context.mlsDecryptionService)
    //        XCTAssertNil(context.proteusService)
    //        XCTAssertNil(context.coreCrypto)
    //    }

    // MARK: - Helpers

    private func createCoreCryptoKeyIfNeeded() {
        let keyProvider = CoreCryptoKeyProvider()
        _ = try? keyProvider.coreCryptoKey(createIfNeeded: true)
    }

    private func makeMockCoreDataStack(userIdentifier: UUID) throws -> CoreDataStack {
        let appGroupID = try XCTUnwrap(Bundle.main.applicationGroupIdentifier)
        let sharedContainerURL = FileManager.sharedContainerDirectory(for: appGroupID)
        let account = Account(userName: "", userIdentifier: userIdentifier)

        let coreDataStack = CoreDataStack(
            account: account,
            applicationContainer: sharedContainerURL,
            inMemoryStore: true
        )

        let expectation = self.expectation(description: "")
        var coreDataError: Error?
        coreDataStack.loadStores { error in
            coreDataError = error
            expectation.fulfill()
        }
        waitForExpectations(timeout: 0.5)

        if let coreDataError {
            throw coreDataError
        }

        return coreDataStack
    }

    private func createSelfUserAndClient(accountIdentifier: UUID, syncContext: NSManagedObjectContext) {
        let selfUser = ZMUser.selfUser(in: syncContext)
        selfUser.remoteIdentifier = accountIdentifier
        selfUser.domain = "example.com"

        let selfClient = UserClient.insertNewObject(in: syncContext)
        selfClient.remoteIdentifier = "selfClient"
        selfClient.user = selfUser

        syncContext.setPersistentStoreMetadata(selfClient.remoteIdentifier!, key: ZMPersistedClientIdKey)
        syncContext.saveOrRollback()
    }
}
