//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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
        spinMainQueue(withTimeout: 0.2) // the delayed save will wait 0.1 seconds

        // THEN
        XCTAssertTrue(executed)
        XCTAssertTrue(blockExecuted)
        XCTAssertTrue(contextSaved)
    }

    func waitForStatus(_ state: ZMNetworkState) -> Bool {
        return waitOnMainLoop(until: {
            return self.sut.networkState == state
        }, timeout: 0.5)
    }

    func waitForOfflineStatus() -> Bool {
        return waitForStatus(.offline)
    }

    func waitForOnlineSynchronizingStatus() -> Bool {
        return waitForStatus(.onlineSynchronizing)
    }

    func testThatWeSetUserSessionToOnlineWhenWeDidReceiveData() {
        // WHEN
        sut.didGoOffline()
        sut.didReceiveData()

        // THEN
        XCTAssertTrue(waitForOnlineSynchronizingStatus())

    }

    func testThatWeSetUserSessionToOfflineWhenARequestFails() {
        // WHEN
        sut.didGoOffline()

        // THEN
        XCTAssertTrue(waitForOfflineStatus())
    }

    func testThatItNotifiesThirdPartyServicesWhenSyncIsDone() {
        // GIVEN
        XCTAssertEqual(thirdPartyServices.uploadCount, 0)

        let handler = MockActionHandler<GetFeatureConfigsAction>(
            result: .success(()),
            context: syncMOC.notificationContext
        )

        // WHEN
        syncMOC.performAndWait {
            sut.didFinishQuickSync()
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        withExtendedLifetime(handler) {
            XCTAssertEqual(thirdPartyServices.uploadCount, 1)
        }
    }

    func testThatItOnlyNotifiesThirdPartyServicesOnce() {
        // GIVEN
        XCTAssertEqual(thirdPartyServices.uploadCount, 0)

        mockGetFeatureConfigsActionHandler = MockActionHandler<GetFeatureConfigsAction>(
            results: [.success(()), .success(())],
            context: syncMOC.notificationContext
        )

        // WHEN
        syncMOC.performAndWait {
            sut.didFinishQuickSync()
            sut.didStartQuickSync()
            sut.didFinishQuickSync()
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        XCTAssertEqual(thirdPartyServices.uploadCount, 1)
    }

    func testThatItNotifiesThirdPartyServicesWhenEnteringBackground() {
        // GIVEN
        XCTAssertEqual(self.thirdPartyServices.uploadCount, 0)

        // WHEN
        self.sut.applicationDidEnterBackground(nil)

        // THEN
        XCTAssertEqual(thirdPartyServices.uploadCount, 1)
    }

    func testThatItNotifiesThirdPartyServicesAgainAfterEnteringForeground_1() {
        // GIVEN
        XCTAssertEqual(thirdPartyServices.uploadCount, 0)

        // WHEN
        sut.applicationDidEnterBackground(nil)
        sut.applicationWillEnterForeground(nil)
        sut.applicationDidEnterBackground(nil)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        XCTAssertEqual(thirdPartyServices.uploadCount, 2)
    }

    func testThatItNotifiesThirdPartyServicesAgainAfterEnteringForeground_2() {
        // GIVEN
        XCTAssertEqual(thirdPartyServices.uploadCount, 0)

        mockGetFeatureConfigsActionHandler = MockActionHandler<GetFeatureConfigsAction>(
            results: [.success(()), .success(())],
            context: syncMOC.notificationContext
        )

        // whe
        syncMOC.performAndWait {
            sut.didFinishQuickSync()
        }
        sut.applicationDidEnterBackground(nil)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        XCTAssertEqual(thirdPartyServices.uploadCount, 1)

        sut.applicationWillEnterForeground(nil)

        syncMOC.performAndWait {
            sut.didStartQuickSync()
            sut.didFinishQuickSync()
        }
        sut.applicationDidEnterBackground(nil)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        XCTAssertEqual(thirdPartyServices.uploadCount, 2)
    }

    func testThatWeDoNotSetUserSessionToSyncDoneWhenSyncIsDoneIfWeWereNotSynchronizing() {
        // WHEN
        sut.didGoOffline()

        mockGetFeatureConfigsActionHandler = MockActionHandler<GetFeatureConfigsAction>(
            results: [.success(())],
            context: syncMOC.notificationContext
        )

        syncMOC.performAndWait {
            sut.didFinishQuickSync()
        }

        // THEN
        XCTAssertTrue(waitForOfflineStatus())
    }

    func testThatWeSetUserSessionToSynchronizingWhenSyncIsStarted() {
        // WHEN
        syncMOC.performAndWait {
            sut.didStartQuickSync()
        }

        // THEN
        XCTAssertTrue(waitForOnlineSynchronizingStatus())
    }

    func testThatWeCanGoBackOnlineAfterGoingOffline() {
        // WHEN
        sut.didGoOffline()

        // THEN
        XCTAssertTrue(waitForOfflineStatus())

        // WHEN
        sut.didReceiveData()

        // THEN
        XCTAssertTrue(waitForOnlineSynchronizingStatus())

    }

    func testThatWeCanGoBackOfflineAfterGoingOnline() {
        // WHEN
        sut.didGoOffline()

        // THEN
        XCTAssertTrue(waitForOfflineStatus())

        // WHEN
        sut.didReceiveData()

        // THEN
        XCTAssertTrue(waitForOnlineSynchronizingStatus())

        // WHEN
        sut.didGoOffline()

        // THEN
        XCTAssertTrue(waitForOfflineStatus())
    }

    func testThatItNotifiesObserversWhenTheNetworkStatusBecomesOnline() {
        // GIVEN
        let stateRecorder = NetworkStateRecorder()
        sut.didGoOffline()
        XCTAssertTrue(waitForOfflineStatus())
        XCTAssertEqual(sut.networkState, .offline)

        // WHEN
        let token = ZMNetworkAvailabilityChangeNotification.addNetworkAvailabilityObserver(stateRecorder, userSession: sut)
        sut.didReceiveData()

        // THEN
        withExtendedLifetime(token) {
            XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
            XCTAssertEqual(stateRecorder.stateChanges.count, 1)
            XCTAssertEqual(stateRecorder.stateChanges.first, .onlineSynchronizing)
        }
    }

    func testThatItDoesNotNotifiesObserversWhenTheNetworkStatusWasAlreadyOnline() {
        // GIVEN
        let stateRecorder = NetworkStateRecorder()

        // WHEN
        let token = ZMNetworkAvailabilityChangeNotification.addNetworkAvailabilityObserver(stateRecorder, userSession: sut)
        sut.didReceiveData()

        // THEN
        withExtendedLifetime(token) {
            XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
            XCTAssertEqual(stateRecorder.stateChanges.count, 0)
        }
    }

    func testThatItNotifiesObserversWhenTheNetworkStatusBecomesOffline() {
        // GIVEN
        let stateRecorder = NetworkStateRecorder()

        // WHEN
        let token = ZMNetworkAvailabilityChangeNotification.addNetworkAvailabilityObserver(stateRecorder, userSession: sut)
        sut.didGoOffline()

        // THEN
        withExtendedLifetime(token) {
            XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
            XCTAssertEqual(stateRecorder.stateChanges.count, 1)
            XCTAssertEqual(stateRecorder.stateChanges.first, .offline)
        }
    }

    func testThatItDoesNotNotifiesObserversWhenTheNetworkStatusWasAlreadyOffline() {
        // GIVEN
        let stateRecorder = NetworkStateRecorder()

        sut.didGoOffline()
        XCTAssertTrue(waitForOfflineStatus())

        // WHEN
        let token = ZMNetworkAvailabilityChangeNotification.addNetworkAvailabilityObserver(stateRecorder, userSession: sut)
        sut.didGoOffline()

        // THEN
        withExtendedLifetime(token) {
            XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
            XCTAssertEqual(stateRecorder.stateChanges.count, 0)
        }
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

        let handler = MockActionHandler<GetFeatureConfigsAction>(
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
        withExtendedLifetime(handler) {
            XCTAssertFalse(mockMLSService.performPendingJoins_Invocations.isEmpty)
            XCTAssertFalse(mockMLSService.uploadKeyPackagesIfNeeded_Invocations.isEmpty)
            XCTAssertFalse(mockMLSService.updateKeyMaterialForAllStaleGroupsIfNeeded_Invocations.isEmpty)
            XCTAssertFalse(mockMLSService.commitPendingProposalsIfNeeded_Invocations.isEmpty)
        }
    }
}
