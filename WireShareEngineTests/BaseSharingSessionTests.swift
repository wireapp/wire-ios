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

class BaseSharingSessionTests: ZMTBaseTest {

    var moc: NSManagedObjectContext!
    var sharingSession: SharingSession!
    var authenticationStatus: FakeAuthenticationStatus!
    var accountIdentifier: UUID!

    override func setUp() {
        super.setUp()

        accountIdentifier = UUID.create()
        authenticationStatus = FakeAuthenticationStatus()
        let url = try! FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)

        var directory: ManagedObjectContextDirectory!
        StorageStack.shared.createStorageAsInMemory = true
        StorageStack.shared.createManagedObjectContextDirectory(accountIdentifier: accountIdentifier,
                                                                applicationContainer: url) {
            directory = $0
        }
        directory.uiContext.add(dispatchGroup)
        directory.syncContext.add(dispatchGroup)
        directory.searchContext.add(dispatchGroup)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        let mockTransport = MockTransportSession(dispatchGroup: dispatchGroup)
        let transportSession = mockTransport.mockedTransportSession()

        let saveNotificationPersistence = ContextDidSaveNotificationPersistence(accountContainer: url)
        let analyticsEventPersistence = ShareExtensionAnalyticsPersistence(accountContainer: url)

        let requestGeneratorStore = RequestGeneratorStore(strategies: [])
        let registrationStatus = ClientRegistrationStatus(context: directory.syncContext)
        let linkPreviewDetector = LinkPreviewDetector()
        let operationLoop = RequestGeneratingOperationLoop(
            userContext: directory.uiContext,
            syncContext: directory.syncContext,
            callBackQueue: .main,
            requestGeneratorStore: requestGeneratorStore,
            transportSession: transportSession
        )
        let applicationStatusDirectory = ApplicationStatusDirectory(
            transportSession: transportSession,
            authenticationStatus: authenticationStatus,
            clientRegistrationStatus: registrationStatus,
            linkPreviewDetector: linkPreviewDetector
        )

        let strategyFactory = StrategyFactory(
            syncContext: directory.syncContext,
            applicationStatus: applicationStatusDirectory,
            linkPreviewPreprocessor: LinkPreviewPreprocessor(linkPreviewDetector: linkPreviewDetector, managedObjectContext: directory.syncContext)
        )

        sharingSession = try! SharingSession(
            contextDirectory: directory,
            transportSession: transportSession,
            cachesDirectory: url,
            saveNotificationPersistence: saveNotificationPersistence,
            analyticsEventPersistence: analyticsEventPersistence,
            applicationStatusDirectory: applicationStatusDirectory,
            operationLoop: operationLoop,
            strategyFactory: strategyFactory
        )

        moc = sharingSession.userInterfaceContext
        
        setupSelfUser()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }
    
    func setupSelfUser() {
        ZMUser.selfUser(in: sharingSession.userInterfaceContext).remoteIdentifier = accountIdentifier
        sharingSession.userInterfaceContext.saveOrRollback()
    }

    override func tearDown() {
        sharingSession = nil
        authenticationStatus = nil
        moc = nil
        StorageStack.reset()
        super.tearDown()
    }

}
