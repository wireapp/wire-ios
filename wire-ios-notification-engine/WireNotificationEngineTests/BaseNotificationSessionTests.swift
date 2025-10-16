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

import Foundation
import WireDataModel
import WireDataModelSupport
import WireMockTransport
import WireRequestStrategy
import WireTesting
import XCTest

@testable import WireNotificationEngine

class FakeAuthenticationStatus: AuthenticationStatusProvider {
    var state: AuthenticationState = .authenticated
}

class BaseTest: ZMTBaseTest {

    var authenticationStatus: FakeAuthenticationStatus!
    var accountIdentifier: UUID!
    var coreDataStack: CoreDataStack!
    var transportSession: ZMTransportSession!
    var cachesDirectory: URL!
    var saveNotificationPersistence: ContextDidSaveNotificationPersistence!
    var applicationStatusDirectory: ApplicationStatusDirectory!
    var operationLoop: RequestGeneratingOperationLoop!
    var pushNotificationStatus: PushNotificationStatus!
    var pushNotificationStrategy: PushNotificationStrategy!
    var mockCryptoboxMigrationManager: MockCryptoboxMigrationManagerInterface!
    var mockEARService: MockEARServiceInterface!
    var mockProteusService: MockProteusServiceInterface!
    var mockMLSDecryptionService: MLSDecryptionServiceInterface!
    var lastEventIDRepository: LastEventIDRepository!
    var apiVersion = WireTransport.APIVersion.v5

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

        lastEventIDRepository = LastEventIDRepository(
            userID: accountIdentifier,
            sharedUserDefaults: .temporary()
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

        let requestGeneratorStore = RequestGeneratorStore(strategies: [], apiVersion: apiVersion)
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
            managedObjectContext: coreDataStack.syncContext,
            transportSession: transportSession,
            authenticationStatus: authenticationStatus,
            clientRegistrationStatus: registrationStatus,
            linkPreviewDetector: linkPreviewDetector,
            lastEventIDRepository: lastEventIDRepository
        )

        pushNotificationStatus = PushNotificationStatus(
            managedObjectContext: coreDataStack.syncContext,
            lastEventIDRepository: lastEventIDRepository
        )

        pushNotificationStrategy = PushNotificationStrategy(
            syncContext: coreDataStack.syncContext,
            applicationStatus: applicationStatusDirectory,
            pushNotificationStatus: pushNotificationStatus,
            lastEventIDRepository: lastEventIDRepository
        )

        await createSelfUserAndClient()

        mockCryptoboxMigrationManager = MockCryptoboxMigrationManagerInterface()
        mockCryptoboxMigrationManager.isMigrationNeededAccountDirectory_MockValue = false

        mockEARService = MockEARServiceInterface()
        mockProteusService = MockProteusServiceInterface()
        mockMLSDecryptionService = MockMLSDecryptionServiceInterface()
    }

    func createSelfUserAndClient() async {
        let context = coreDataStack.syncContext

        await context.perform {
            let selfUser = ZMUser.selfUser(in: context)
            selfUser.remoteIdentifier = self.accountIdentifier
            selfUser.domain = "example.com"

            let selfClient = UserClient.insertNewObject(in: context)
            selfClient.remoteIdentifier = "selfClient"
            selfClient.user = selfUser

            context.setPersistentStoreMetadata(selfClient.remoteIdentifier!, key: ZMPersistedClientIdKey)
            context.saveOrRollback()
        }
    }

    override func tearDown() {
        authenticationStatus = nil
        accountIdentifier = nil
        coreDataStack = nil
        cachesDirectory = nil
        saveNotificationPersistence = nil
        applicationStatusDirectory = nil
        operationLoop = nil
        transportSession = nil
        pushNotificationStatus = nil
        pushNotificationStrategy = nil
        mockCryptoboxMigrationManager = nil
        lastEventIDRepository = nil
        super.tearDown()
    }

    func createNotificationSession() throws -> NotificationSession {

        try NotificationSession(
            coreDataStack: coreDataStack,
            transportSession: transportSession,
            cachesDirectory: cachesDirectory,
            saveNotificationPersistence: saveNotificationPersistence,
            applicationStatusDirectory: applicationStatusDirectory,
            operationLoop: operationLoop,
            accountIdentifier: accountIdentifier,
            pushNotificationStrategy: pushNotificationStrategy,
            cryptoboxMigrationManager: mockCryptoboxMigrationManager,
            earService: mockEARService,
            proteusService: mockProteusService,
            mlsDecryptionService: mockMLSDecryptionService,
            lastEventIDRepository: lastEventIDRepository
        )
    }
}
