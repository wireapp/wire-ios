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

import Combine
import Foundation
import WireDataModelSupport
import WireTesting
import WireTestingPackage

@testable import WireSyncEngine
@testable import WireSyncEngineSupport

final class ZMUserSessionTests: ZMUserSessionTestsBase {

    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        cancellables = []
    }

    override func tearDown() {
        super.tearDown()
        cancellables = nil
    }

    func testThatSyncContextReturnsSelfForLinkedSyncContext() {
        // GIVEN
        XCTAssertNotNil(sut.syncManagedObjectContext)
        // WHEN & THEN
        coreDataStack.syncContext.performAndWait {
            XCTAssertEqual(self.sut.syncManagedObjectContext, self.sut.syncManagedObjectContext.zm_sync)
        }
    }

    func testThatUIContextReturnsSelfForLinkedUIContext() {
        // GIVEN
        XCTAssertNotNil(sut.managedObjectContext)
        // WHEN & THEN
        XCTAssertEqual(sut.managedObjectContext, sut.managedObjectContext.zm_userInterface)
    }

    func testThatSyncContextReturnsLinkedUIContext() {
        // GIVEN
        XCTAssertNotNil(sut.syncManagedObjectContext)
        // WHEN & THEN
        coreDataStack.syncContext.performAndWait {
            XCTAssertEqual(self.sut.syncManagedObjectContext.zm_userInterface, self.sut.managedObjectContext)
        }
    }

    func testThatUIContextReturnsLinkedSyncContext() {
        // GIVEN
        XCTAssertNotNil(sut.managedObjectContext)
        // WHEN & THEN
        XCTAssertEqual(sut.managedObjectContext.zm_sync, sut.syncManagedObjectContext)
    }

    func testThatLinkedUIContextIsNotStrongReferenced() {
        // GIVEN
        let mocSync: NSManagedObjectContext? = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        var mocUI: NSManagedObjectContext? = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)

        mocUI?.zm_sync = mocSync
        mocSync?.performAndWait {
            mocSync?.zm_userInterface = mocUI
        }
        XCTAssertNotNil(mocUI?.zm_sync)
        mocSync?.performAndWait {
            XCTAssertNotNil(mocSync?.zm_userInterface)
        }
        // WHEN
        mocUI = nil

        // THEN
        XCTAssertNotNil(mocSync)
        mocSync?.performAndWait {
            XCTAssertNil(mocSync?.zm_userInterface)
        }
    }

    func testThatLinkedSyncContextIsNotStrongReferenced() {
        // GIVEN
        var mocSync: NSManagedObjectContext? = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        let mocUI: NSManagedObjectContext? = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)

        mocUI?.zm_sync = mocSync
        mocSync?.performAndWait {
            mocSync?.zm_userInterface = mocUI
        }

        XCTAssertNotNil(mocUI?.zm_sync)
        mocSync?.performAndWait {
            XCTAssertNotNil(mocSync?.zm_userInterface)
        }
        // WHEN
        mocSync = nil

        // THEN
        XCTAssertNotNil(mocUI)
        XCTAssertNil(mocUI?.zm_sync)
    }

    func testItSlowSyncsAfterRegisteringClient() async throws {
        // GIVEN
        mockCoreCryptoProvider.registerMlsTransport_MockMethod = { _ in }

        let userClient = await syncMOC.perform {
            self.createSelfClient()
        }

        // WHEN
        await syncMOC.perform {
            self.sut.didRegisterSelfUserClient(userClient)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        let expectation = expectation(description: "wait for trigger slow")
        sut.clientSessionComponent?.syncStateSubject.sink { state in
            if state == .initialSyncing(.pullLastEventID) {
                expectation.fulfill()
            }
        }.store(in: &cancellables)

        wait(for: [expectation])
    }

    func test_didRegisterSelfUserClient_withConsumableNotificationsCapabableEnablesSyncV3() async throws {
        // GIVEN
        mockCoreCryptoProvider.registerMlsTransport_MockMethod = { _ in }
        syncMOC.performAndWait {
            Feature.updateOrCreate(havingName: .consumableNotifications, in: syncMOC) {
                $0.status = .enabled
            }
        }
        let userClient = await syncMOC.perform {
            self.createSelfClient(capabilities: [.consumableNotifications, .legalholdConsent])
        }

        // WHEN
        await syncMOC.perform {
            self.sut.didRegisterSelfUserClient(userClient)
        }

        // THEN
        XCTAssertTrue(sut.journal[.isConsumableNotificationsEnabled])
    }

    func testThatPerformChangesAreDoneSynchronouslyOnTheMainQueue() {
        // GIVEN
        var executed = false
        var contextSaved = false

        // expect
        NotificationCenter.default
            .addObserver(forName: .NSManagedObjectContextDidSave, object: uiMOC, queue: nil) { _ in
                contextSaved = true
            }

        // WHEN
        sut.perform {
            XCTAssertEqual(OperationQueue.current, OperationQueue.main)
            XCTAssertFalse(executed)
            XCTAssertFalse(contextSaved)
            executed = true
            ZMConversation.insertNewObject(in: self.uiMOC) // force a save
        }

        // THEN
        XCTAssertTrue(contextSaved)
        XCTAssertTrue(executed)
    }

    func testThatEnqueueChangesAreDoneAsynchronouslyOnTheMainQueue() {
        // GIVEN
        var executed = false
        var contextSaved = false

        // expect
        NotificationCenter.default
            .addObserver(forName: .NSManagedObjectContextDidSave, object: uiMOC, queue: nil) { _ in
                contextSaved = true
            }

        // WHEN
        sut.enqueue {
            XCTAssertEqual(OperationQueue.current, OperationQueue.main)
            XCTAssertFalse(executed)
            XCTAssertFalse(contextSaved)
            executed = true
            ZMConversation.insertNewObject(in: self.uiMOC) // force a save
        }

        // THEN
        XCTAssertFalse(executed)
        XCTAssertFalse(contextSaved)

        // and WHEN
        spinMainQueue(withTimeout: 0.05)

        // THEN
        XCTAssertTrue(contextSaved)
        XCTAssertTrue(executed)
    }

    func testThatEnqueueChangesAreDoneAsynchronouslyOnTheMainQueueWithCompletionHandler() {
        // GIVEN
        var executed = false
        var blockExecuted = false
        var contextSaved = false

        // expect
        NotificationCenter.default
            .addObserver(forName: .NSManagedObjectContextDidSave, object: uiMOC, queue: nil) { _ in
                contextSaved = true
            }

        // WHEN
        sut.enqueue {
            XCTAssertEqual(OperationQueue.current, OperationQueue.main)
            XCTAssertFalse(executed)
            XCTAssertFalse(contextSaved)
            executed = true
            ZMConversation.insertNewObject(in: self.uiMOC) // force a save
        } completionHandler: {
            XCTAssertTrue(executed)
            XCTAssertEqual(OperationQueue.current, OperationQueue.main)
            XCTAssertFalse(blockExecuted)
            XCTAssertTrue(contextSaved)
            blockExecuted = true
        }

        // THEN
        XCTAssertFalse(executed)
        XCTAssertFalse(blockExecuted)
        XCTAssertFalse(contextSaved)

        // and WHEN
        spinMainQueue(withTimeout: 0.05)

        // THEN
        XCTAssertTrue(executed)
        XCTAssertTrue(blockExecuted)
        XCTAssertTrue(contextSaved)
    }

    func testThatEnqueueDelayedChangesAreDoneAsynchronouslyOnTheMainQueueWithCompletionHandler() {
        // GIVEN
        var executed = false
        var blockExecuted = false
        var contextSaved = false

        // expect
        NotificationCenter.default
            .addObserver(forName: .NSManagedObjectContextDidSave, object: uiMOC, queue: nil) { _ in
                contextSaved = true
            }

        // WHEN
        sut.enqueueDelayed {
            XCTAssertEqual(OperationQueue.current, OperationQueue.main)
            XCTAssertFalse(executed)
            XCTAssertFalse(contextSaved)
            executed = true
            ZMConversation.insertNewObject(in: self.uiMOC) // force a save
        } completionHandler: {
            XCTAssertTrue(executed)
            XCTAssertEqual(OperationQueue.current, OperationQueue.main)
            XCTAssertFalse(blockExecuted)
            XCTAssertTrue(contextSaved)
            blockExecuted = true
        }

        // THEN
        XCTAssertFalse(executed)
        XCTAssertFalse(blockExecuted)
        XCTAssertFalse(contextSaved)

        // and WHEN
        let waitExpectation = XCTestExpectation().inverted()
        wait(for: [waitExpectation], timeout: 0.5)

        // THEN
        XCTAssertTrue(executed)
        XCTAssertTrue(blockExecuted)
        XCTAssertTrue(contextSaved)
    }

    func testThatWeSetUserSessionToOnlineWhenWeDidReceiveData() {
        // WHEN
        sut.didGoOffline()
        sut.didReceiveData()

        // THEN
        wait(forConditionToBeTrue: self.sut.networkState == .onlineSynchronizing, timeout: 5)
    }

    func testThatWeSetUserSessionToOfflineWhenARequestFails() {
        // WHEN
        sut.didGoOffline()

        // THEN
        wait(forConditionToBeTrue: self.sut.networkState == .offline, timeout: 5)
    }

    func testThatWeDoNotSetUserSessionToSyncDoneWhenSyncIsDoneIfWeWereNotSynchronizing() {
        // WHEN
        sut.didGoOffline()

        syncMOC.performAndWait {
            sut.didFinishIncrementalSync(isRecovering: false)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 1))

        // THEN
        wait(forConditionToBeTrue: self.sut.networkState == .offline, timeout: 5)
    }

    func testThatWeSetUserSessionToSynchronizingWhenSyncIsStarted() {
        // WHEN
        syncMOC.performAndWait {
            sut.didStartIncrementalSync()
        }

        // THEN
        wait(forConditionToBeTrue: self.sut.networkState == .onlineSynchronizing, timeout: 5)
    }

    func testThatWeCanGoBackOnlineAfterGoingOffline() {
        // WHEN
        sut.didGoOffline()

        // THEN
        wait(forConditionToBeTrue: self.sut.networkState == .offline, timeout: 5)

        // WHEN
        sut.didReceiveData()

        // THEN
        wait(forConditionToBeTrue: self.sut.networkState == .onlineSynchronizing, timeout: 5)
    }

    func testThatWeCanGoBackOfflineAfterGoingOnline() {
        // WHEN
        sut.didGoOffline()

        // THEN
        wait(forConditionToBeTrue: self.sut.networkState == .offline, timeout: 5)

        // WHEN
        sut.didReceiveData()

        // THEN
        wait(forConditionToBeTrue: self.sut.networkState == .onlineSynchronizing, timeout: 5)

        // WHEN
        sut.didGoOffline()

        // THEN
        wait(forConditionToBeTrue: self.sut.networkState == .offline, timeout: 5)
    }

    func testThatItSetsTheMinimumBackgroundFetchInterval() {
        XCTAssertNotEqual(application.minimumBackgroundFetchInverval, UIApplication.backgroundFetchIntervalNever)
        XCTAssertGreaterThanOrEqual(
            application.minimumBackgroundFetchInverval,
            UIApplication.backgroundFetchIntervalMinimum
        )
        XCTAssertLessThanOrEqual(application.minimumBackgroundFetchInverval, TimeInterval(20 * 60))
    }

    func testThatItMarksTheConversationsAsRead() throws {
        // GIVEN
        let conversationsRange: CountableClosedRange = 1 ... 10

        let conversations: [ZMConversation] = conversationsRange.map { _ in
            self.sut.insertConversationWithUnreadMessage()
        }

        try uiMOC.save()

        // WHEN
        sut.markAllConversationsAsRead()

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        uiMOC.refreshAllObjects()
        XCTAssertEqual(conversations.filter { $0.firstUnreadMessage != nil }.count, 0)
    }

    func test_didFinishQuickSync_CalculateSupportedProtocolsIfNoProtocols() {
        syncMOC.performAndWait {
            // GIVEN
            ZMUser.selfUser(in: self.syncMOC).supportedProtocols = .init()

            // WHEN
            sut.didFinishIncrementalSync(isRecovering: false)
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        let supportedProtocols = syncMOC.performAndWait { ZMUser.selfUser(in: self.syncMOC).supportedProtocols }

        XCTAssertTrue(supportedProtocols.contains(.proteus))
    }

    func test_OnSelfClientInvalidated() async throws {
        // GIVEN
        let applicationStatusDirectory = sut.applicationStatusDirectory
        let clientRegistrationStatus = applicationStatusDirectory.clientRegistrationStatus
        let clientUpdateStatus = applicationStatusDirectory.clientUpdateStatus
        clientRegistrationStatus.emailCredentials = .credentials(
            email: "test@wire.com",
            password: "7@9xIZ"
        )

        clientUpdateStatus.needsToVerifySelfClient = true

        // WHEN
        await sut.onSelfClientInvalidated()

        // THEN
        XCTAssertEqual(clientRegistrationStatus.emailCredentials, nil)
        XCTAssertEqual(clientRegistrationStatus.cookieProvider.isAuthenticated, false)
        XCTAssertEqual(clientUpdateStatus.needsToVerifySelfClient, false)
    }
}
