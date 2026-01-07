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

import WireDataModel
import WireLinkPreview
import WireMockTransport
import WireRequestStrategy
import WireTesting
import XCTest
@testable import WireShareEngine

@testable import WireDataModelSupport

final class FakeAuthenticationStatus: AuthenticationStatusProvider {
    var state: AuthenticationState = .authenticated
}

class BaseSharingSessionTests: BaseTest {

    var sharingSession: SharingSession!
    var moc: NSManagedObjectContext!

    override func setUp() async throws {
        try await super.setUp()
        sharingSession = try await createSharingSession()
        moc = sharingSession.userInterfaceContext
    }

    override func tearDown() {
        sharingSession = nil
        moc = nil
        super.tearDown()
    }
}

class BaseTest: ZMTBaseTest {

    var authenticationStatus: FakeAuthenticationStatus!
    var accountIdentifier: UUID!
    var coreDataStack: CoreDataStack!
    var transportSession: ZMTransportSession!
    var cachesDirectory: URL!
    var saveNotificationPersistence: ContextDidSaveNotificationPersistence!
    var analyticsEventPersistence: ShareExtensionAnalyticsPersistence!
    var applicationStatusDirectory: ApplicationStatusDirectory!
    var operationLoop: RequestGeneratingOperationLoop!
    var strategyFactory: StrategyFactory!
    var mockEARService: MockEARServiceInterface!
    var mockProteusService: MockProteusServiceInterface!
    var mockMLSService: MockMLSServiceInterface!
    var mockMLSDecryptionService: MLSDecryptionServiceInterface!

    override func setUp() async throws {
        try await super.setUp()

        accountIdentifier = UUID.create()
        authenticationStatus = FakeAuthenticationStatus()
        cachesDirectory = try! FileManager.default.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        let account = Account(
            userName: "",
            userIdentifier: accountIdentifier
        )

        coreDataStack = CoreDataStack(
            account: account,
            applicationContainer: cachesDirectory,
            inMemoryStore: true,
            dispatchGroup: dispatchGroup,
            localDomain: "wire.com",
            isFederationEnabled: false
        )

        try await coreDataStack.load()

        let mockTransport = MockTransportSession(dispatchGroup: dispatchGroup)
        transportSession = mockTransport.mockedTransportSession()

        saveNotificationPersistence = ContextDidSaveNotificationPersistence(accountContainer: cachesDirectory)
        analyticsEventPersistence = ShareExtensionAnalyticsPersistence(accountContainer: cachesDirectory)

        let requestGeneratorStore = RequestGeneratorStore(strategies: [], apiVersion: .v0)
        let registrationStatus = ClientRegistrationStatus(context: coreDataStack.syncContext)
        let linkPreviewDetector = LinkPreviewDetector()

        operationLoop = RequestGeneratingOperationLoop(
            userContext: coreDataStack.viewContext,
            syncContext: coreDataStack.syncContext,
            callBackQueue: .main,
            requestGeneratorStore: requestGeneratorStore,
            transportSession: transportSession
        )

        applicationStatusDirectory = ApplicationStatusDirectory(
            transportSession: transportSession,
            authenticationStatus: authenticationStatus,
            clientRegistrationStatus: registrationStatus,
            linkPreviewDetector: linkPreviewDetector
        )

        strategyFactory = StrategyFactory(
            syncContext: coreDataStack.syncContext,
            applicationStatus: applicationStatusDirectory,
            linkPreviewPreprocessor: LinkPreviewPreprocessor(
                linkPreviewDetector: linkPreviewDetector,
                managedObjectContext: coreDataStack.syncContext
            ),
            transportSession: transportSession,
            initiateResetMLSConversationUseCase: NullInitiateResetMLSConversationUseCase(),
            apiVersion: .v0,
            localDomain: "wire.com"
        )

        let context = coreDataStack.syncContext

        await context.perform {
            let selfUser = ZMUser.selfUser(in: context)
            selfUser.remoteIdentifier = self.accountIdentifier
            selfUser.domain = "wire.com"

            let selfClient = UserClient.insertNewObject(in: context)
            selfClient.remoteIdentifier = "selfClient"
            selfClient.user = selfUser

            context.setPersistentStoreMetadata(selfClient.remoteIdentifier!, key: ZMPersistedClientIdKey)
            context.saveOrRollback()
        }

        mockEARService = MockEARServiceInterface()
        mockEARService.enableEncryptionAtRestContextSkipMigration_MockMethod = { _, _ in }
        mockEARService.disableEncryptionAtRestContextSkipMigration_MockMethod = { _, _ in }
        mockEARService.unlockDatabase_MockMethod = {}
        mockEARService.lockDatabase_MockMethod = {}

        mockProteusService = MockProteusServiceInterface()
        mockMLSService = MockMLSServiceInterface()
        mockMLSDecryptionService = MockMLSDecryptionServiceInterface()

        sharedUserDefaults = .temporary()
    }

    override func tearDown() {
        authenticationStatus = nil
        coreDataStack = nil
        transportSession = nil
        cachesDirectory = nil
        saveNotificationPersistence = nil
        analyticsEventPersistence = nil
        applicationStatusDirectory = nil
        operationLoop = nil
        strategyFactory = nil
        mockEARService = nil
        mockProteusService = nil
        mockMLSDecryptionService = nil
        super.tearDown()
    }

    func createSharingSession() async throws -> SharingSession {
        let earService = EARService(
            accountID: accountIdentifier,
            databaseContexts: [coreDataStack.viewContext, coreDataStack.syncContext],
            sharedUserDefaults: sharedUserDefaults,
            authenticationContext: MockAuthenticationContextProtocol()
        )
        return try await SharingSession(
            accountIdentifier: accountIdentifier,
            coreDataStack: coreDataStack,
            transportSession: transportSession,
            cachesDirectory: cachesDirectory,
            saveNotificationPersistence: saveNotificationPersistence,
            analyticsEventPersistence: analyticsEventPersistence,
            applicationStatusDirectory: applicationStatusDirectory,
            operationLoop: operationLoop,
            strategyFactory: strategyFactory,
            appLockConfig: AppLockController.LegacyConfig(),
            earService: earService,
            contextStorage: MockLAContextStorable(),
            proteusService: mockProteusService,
            mlsService: mockMLSService,
            mlsDecryptionService: mockMLSDecryptionService,
            sharedUserDefaults: .temporary()
        )
    }

}
