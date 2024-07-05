//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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
import WireDataModelSupport
import WireSyncEngine
import WireTesting

@testable import WireSyncEngineSupport

final class ZMUserSessionTests: ZMUserSessionTestsBase {

    func testThatSyncContextReturnsSelfForLinkedSyncContext() {
        // GIVEN
        XCTAssertNotNil(self.sut.syncManagedObjectContext)
        // WHEN & THEN
        coreDataStack.syncContext.performAndWait {
            XCTAssertEqual(self.sut.syncManagedObjectContext, self.sut.syncManagedObjectContext.zm_sync)
        }
    }

    func testThatUIContextReturnsSelfForLinkedUIContext() {
        // GIVEN
        XCTAssertNotNil(self.sut.managedObjectContext)
        // WHEN & THEN
        XCTAssertEqual(self.sut.managedObjectContext, self.sut.managedObjectContext.zm_userInterface)
    }

    func testThatSyncContextReturnsLinkedUIContext() {
        // GIVEN
        XCTAssertNotNil(self.sut.syncManagedObjectContext)
        // WHEN & THEN
        coreDataStack.syncContext.performAndWait {
            XCTAssertEqual(self.sut.syncManagedObjectContext.zm_userInterface, self.sut.managedObjectContext)
        }
    }

    func testThatUIContextReturnsLinkedSyncContext() {
        // GIVEN
        XCTAssertNotNil(self.sut.managedObjectContext)
        // WHEN & THEN
        XCTAssertEqual(self.sut.managedObjectContext.zm_sync, self.sut.syncManagedObjectContext)
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

    func testThatItNotfiesTheTransportSessionWhenSelfUserClientIsRegistered() {
        // GIVEN
        let userClient = syncMOC.performAndWait {
            self.createSelfClient()
        }

        // WHEN
        syncMOC.performGroupedBlock { [self] in
            sut.didRegisterSelfUserClient(userClient)
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        syncMOC.performAndWait {
            XCTAssertEqual(mockPushChannel.clientID, userClient.remoteIdentifier)
        }
    }

    func testItSlowSyncsAfterRegisteringMLSClient() async throws {
        // GIVEN
        let userClient = await syncMOC.perform {
            let userClient = self.createSelfClient()
            userClient.mlsPublicKeys = .init(ed25519: "ed25519")
            userClient.needsToUploadMLSPublicKeys = false
            return userClient
        }

        // WHEN
        await syncMOC.perform {
            self.sut.didRegisterSelfUserClient(userClient)
        }

        // THEN
        let syncStatus = try await syncMOC.perform {
            try XCTUnwrap(self.sut.syncStatus as? SyncStatus)
        }

        XCTAssertTrue(syncStatus.isSlowSyncing)
    }

    func testThatPerformChangesAreDoneSynchronouslyOnTheMainQueue() {
        // GIVEN
        var executed: Bool = false
        var contextSaved: Bool = false

        // expect
        NotificationCenter.default.addObserver(forName: .NSManagedObjectContextDidSave, object: uiMOC, queue: nil) { _ in
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
        NotificationCenter.default.addObserver(forName: .NSManagedObjectContextDidSave, object: uiMOC, queue: nil) { _ in
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
        NotificationCenter.default.addObserver(forName: .NSManagedObjectContextDidSave, object: uiMOC, queue: nil) { _ in
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
        NotificationCenter.default.addObserver(forName: .NSManagedObjectContextDidSave, object: uiMOC, queue: nil) { _ in
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

        mockGetFeatureConfigsActionHandler = MockActionHandler<GetFeatureConfigsAction>(
            results: [.success(())],
            context: syncMOC.notificationContext
        )
        let pushSupportedProtocolsActionHandler = MockActionHandler<PushSupportedProtocolsAction>(
            result: .success(()),
            context: syncMOC.notificationContext
        )

        syncMOC.performAndWait {
            sut.didFinishQuickSync()
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 1))

        // THEN
        wait(forConditionToBeTrue: self.sut.networkState == .offline, timeout: 5)
        XCTAssertEqual(mockGetFeatureConfigsActionHandler.performedActions.count, 1)
        XCTAssertEqual(pushSupportedProtocolsActionHandler.performedActions.count, 1)
    }

    func testThatWeSetUserSessionToSynchronizingWhenSyncIsStarted() {
        // WHEN
        syncMOC.performAndWait {
            sut.didStartQuickSync()
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

    func testThatItNotifiesObserversWhenTheNetworkStatusBecomesOnline() {
        // GIVEN
        let stateRecorder = NetworkStateRecorder()
        sut.didGoOffline()
        wait(forConditionToBeTrue: self.sut.networkState == .offline, timeout: 5)
        XCTAssertEqual(sut.networkState, .offline)

        // WHEN
        stateRecorder.observe(in: sut.managedObjectContext.notificationContext)
        sut.didReceiveData()

        // THEN
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(stateRecorder.stateChanges.count, 1)
        XCTAssertEqual(stateRecorder.stateChanges.first, .onlineSynchronizing)
    }

    func testThatItDoesNotNotifiesObserversWhenTheNetworkStatusWasAlreadyOnline() {
        // GIVEN
        let stateRecorder = NetworkStateRecorder()
        stateRecorder.observe(in: sut.managedObjectContext.notificationContext)

        // WHEN
        sut.didReceiveData()

        // THEN
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(stateRecorder.stateChanges.count, 0)
    }

    func testThatItNotifiesObserversWhenTheNetworkStatusBecomesOffline() {
        // GIVEN
        let stateRecorder = NetworkStateRecorder()
        stateRecorder.observe(in: sut.managedObjectContext.notificationContext)

        // WHEN
        sut.didGoOffline()

        // THEN
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(stateRecorder.stateChanges.count, 1)
        XCTAssertEqual(stateRecorder.stateChanges.first, .offline)
    }

    func testThatItDoesNotNotifiesObserversWhenTheNetworkStatusWasAlreadyOffline() {
        // GIVEN
        let stateRecorder = NetworkStateRecorder()

        sut.didGoOffline()
        wait(forConditionToBeTrue: self.sut.networkState == .offline, timeout: 5)

        // WHEN
        stateRecorder.observe(in: sut.managedObjectContext.notificationContext)
        sut.didGoOffline()

        // THEN
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(stateRecorder.stateChanges.count, 0)
    }

    func testThatItSetsTheMinimumBackgroundFetchInterval() {
        XCTAssertNotEqual(application.minimumBackgroundFetchInverval, UIApplication.backgroundFetchIntervalNever)
        XCTAssertGreaterThanOrEqual(application.minimumBackgroundFetchInverval, UIApplication.backgroundFetchIntervalMinimum)
        XCTAssertLessThanOrEqual(application.minimumBackgroundFetchInverval, (TimeInterval) (20 * 60))
    }

    func testThatItMarksTheConversationsAsRead() throws {
        // GIVEN
        let conversationsRange: CountableClosedRange = 1...10

        let conversations: [ZMConversation] = conversationsRange.map { _ in
            return self.sut.insertConversationWithUnreadMessage()
        }

        try self.uiMOC.save()

        // WHEN
        self.sut.markAllConversationsAsRead()

        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        self.uiMOC.refreshAllObjects()
        XCTAssertEqual(conversations.filter { $0.firstUnreadMessage != nil }.count, 0)
    }

    func test_itPerformsPeriodicMLSUpdates_AfterQuickSync() {
        // GIVEN
        mockMLSService.performPendingJoins_MockMethod = {}
        mockMLSService.commitPendingProposalsIfNeeded_MockMethod = {}
        mockMLSService.uploadKeyPackagesIfNeeded_MockMethod = {}
        mockMLSService.updateKeyMaterialForAllStaleGroupsIfNeeded_MockMethod = {}

        let getFeatureConfigsActionHandler = MockActionHandler<GetFeatureConfigsAction>(
            result: .success(()),
            context: syncMOC.notificationContext
        )
        let pushSupportedProtocolsActionHandler = MockActionHandler<PushSupportedProtocolsAction>(
            result: .success(()),
            context: syncMOC.notificationContext
        )

        // MLS client has been registered
        self.syncMOC.performAndWait {
            let selfUserClient = createSelfClient()
            selfUserClient.mlsPublicKeys = UserClient.MLSPublicKeys(ed25519: "somekey")
            selfUserClient.needsToUploadMLSPublicKeys = false
            syncMOC.saveOrRollback()

            // WHEN
            sut.didFinishQuickSync()
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        XCTAssertFalse(mockMLSService.performPendingJoins_Invocations.isEmpty)
        XCTAssertFalse(mockMLSService.uploadKeyPackagesIfNeeded_Invocations.isEmpty)
        XCTAssertFalse(mockMLSService.updateKeyMaterialForAllStaleGroupsIfNeeded_Invocations.isEmpty)
        XCTAssertFalse(mockMLSService.commitPendingProposalsIfNeeded_Invocations.isEmpty)

        XCTAssertEqual(mockRecurringActionService.performActionsIfNeeded_Invocations.count, 1)

        XCTAssertEqual(getFeatureConfigsActionHandler.performedActions.count, 1)
        XCTAssertEqual(pushSupportedProtocolsActionHandler.performedActions.count, 1)
    }
}
