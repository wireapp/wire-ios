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

@testable import WireNotificationEngine
import XCTest
import WireTesting
import WireDataModel
import WireMockTransport
import WireRequestStrategy
import WireDataModelSupport

class BaseTest: ZMTBaseTest {

    var authenticationStatus: FakeAuthenticationStatus!
    var accountIdentifier: UUID!
    var coreDataStack: CoreDataStack!
    var transportSession: ZMTransportSession!
    var saveNotificationPersistence: ContextDidSaveNotificationPersistence!
    var applicationStatusDirectory: ApplicationStatusDirectory!
    var operationLoop: RequestGeneratingOperationLoop!
    var pushNotificationStrategy: PushNotificationStrategy!

    override func setUp() {
        super.setUp()

        accountIdentifier = UUID.create()
        authenticationStatus = FakeAuthenticationStatus()
        let cachesDirectory = try! FileManager.default.url(
            for: .cachesDirectory,
               in: .userDomainMask,
               appropriateFor: nil,
               create: true
        )

        let account = Account(
            userName: "",
            userIdentifier: accountIdentifier
        )

        let lastEventIDRepository = LastEventIDRepository(
            userID: accountIdentifier,
            sharedUserDefaults: sharedUserDefaults
        )

        coreDataStack = CoreDataStack(
            account: account,
            applicationContainer: cachesDirectory,
            inMemoryStore: true,
            dispatchGroup: dispatchGroup
        )

        var coreDataError: Error?
        let expectation = self.expectation(description: "BaseTest.setUp.coreDataStack")
        coreDataStack.loadStores { error in
            coreDataError = error
            expectation.fulfill()
        }
        _ = waitForCustomExpectations(withTimeout: 0.5) // why do we need to use this ugly selfmade expectations?
        XCTAssertNil(coreDataError)

        let mockTransport = MockTransportSession(dispatchGroup: dispatchGroup)
        transportSession = mockTransport.mockedTransportSession()

        saveNotificationPersistence = ContextDidSaveNotificationPersistence(accountContainer: cachesDirectory)

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
            managedObjectContext: coreDataStack.syncContext,
            transportSession: transportSession,
            authenticationStatus: authenticationStatus,
            clientRegistrationStatus: registrationStatus,
            linkPreviewDetector: linkPreviewDetector,
            lastEventIDRepository: lastEventIDRepository
        )

        let pushNotificationStatus = PushNotificationStatus(
            managedObjectContext: coreDataStack.syncContext,
            lastEventIDRepository: lastEventIDRepository
        )
        pushNotificationStrategy = PushNotificationStrategy(
            syncContext: coreDataStack.syncContext,
            applicationStatus: applicationStatusDirectory,
            pushNotificationStatus: pushNotificationStatus,
            notificationsTracker: nil,
            lastEventIDRepository: lastEventIDRepository
        )

        createSelfUserAndClient()
    }

    func createSelfUserAndClient() {
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
        accountIdentifier = nil
        coreDataStack = nil
        saveNotificationPersistence = nil
        applicationStatusDirectory = nil
        operationLoop = nil
        transportSession = nil
        pushNotificationStrategy = nil

        super.tearDown()
    }

    func createNotificationSession() -> NotificationSession {
        NotificationSession(
            applicationStatusDirectory: applicationStatusDirectory,
            accountIdentifier: accountIdentifier,
            coreDataStack: coreDataStack,
            earService: MockEARServiceInterface(),
            eventDecoder: EventDecoder(eventMOC: coreDataStack.eventContext, syncMOC: coreDataStack.syncContext),
            pushNotificationStrategy: pushNotificationStrategy,
            saveNotificationPersistence: saveNotificationPersistence,
            transportSession: transportSession,
            operationLoop: operationLoop
        )
    }
}

// MARK: - Fake Mocks

class FakeAuthenticationStatus: AuthenticationStatusProvider {
    var state: AuthenticationState = .authenticated
}
