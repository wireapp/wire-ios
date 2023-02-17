//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
import WireDataModel
import WireMockTransport
import WireTesting
import WireRequestStrategy
import WireLinkPreview
@testable import WireShareEngine

class FakeAuthenticationStatus: AuthenticationStatusProvider {
    var state: AuthenticationState = .authenticated
}

class BaseSharingSessionTests: BaseTest {

    var sharingSession: SharingSession!
    var moc: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        sharingSession = try! createSharingSession()
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

    override func setUp() {
        super.setUp()

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
            dispatchGroup: dispatchGroup
        )

        coreDataStack.loadStores { error in
            XCTAssertNil(error)
        }

        let mockTransport = MockTransportSession(dispatchGroup: dispatchGroup)
        transportSession = mockTransport.mockedTransportSession()

        saveNotificationPersistence = ContextDidSaveNotificationPersistence(accountContainer: cachesDirectory)
        analyticsEventPersistence = ShareExtensionAnalyticsPersistence(accountContainer: cachesDirectory)

        let requestGeneratorStore = RequestGeneratorStore(strategies: [])
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
            linkPreviewPreprocessor: LinkPreviewPreprocessor(linkPreviewDetector: linkPreviewDetector, managedObjectContext: coreDataStack.syncContext)
        )

        let context = coreDataStack.syncContext

        let selfUser = ZMUser.selfUser(in: context)
        selfUser.remoteIdentifier = accountIdentifier
        selfUser.domain = "example.com"

        let selfClient = UserClient.insertNewObject(in: context)
        selfClient.remoteIdentifier = "selfClient"
        selfClient.user = selfUser

        context.setPersistentStoreMetadata(selfClient.remoteIdentifier!, key: ZMPersistedClientIdKey)
        context.saveOrRollback()

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
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
        super.tearDown()
    }

    func createSharingSession() throws -> SharingSession {
        return try SharingSession(
            accountIdentifier: accountIdentifier,
            coreDataStack: coreDataStack,
            transportSession: transportSession,
            cachesDirectory: cachesDirectory,
            saveNotificationPersistence: saveNotificationPersistence,
            analyticsEventPersistence: analyticsEventPersistence,
            applicationStatusDirectory: applicationStatusDirectory,
            operationLoop: operationLoop,
            strategyFactory: strategyFactory,
            appLockConfig: AppLockController.LegacyConfig()
        )
    }

}
