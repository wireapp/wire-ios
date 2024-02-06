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
        // given
        XCTAssertNotNil(self.sut.syncManagedObjectContext)
        // when & then
        XCTAssertEqual(self.sut.syncManagedObjectContext, self.sut.syncManagedObjectContext.zm_sync)
    }

    func testThatUIContextReturnsSelfForLinkedUIContext() {
        // given
        XCTAssertNotNil(self.sut.managedObjectContext)
        // when & then
        XCTAssertEqual(self.sut.managedObjectContext, self.sut.managedObjectContext.zm_userInterface)
    }

    func testThatSyncContextReturnsLinkedUIContext() {
        // given
        XCTAssertNotNil(self.sut.syncManagedObjectContext)
        // when & then
        XCTAssertEqual(self.sut.syncManagedObjectContext.zm_userInterface, self.sut.managedObjectContext)
    }

    func testThatUIContextReturnsLinkedSyncContext() {
        // given
        XCTAssertNotNil(self.sut.managedObjectContext)
        // when & then
        XCTAssertEqual(self.sut.managedObjectContext.zm_sync, self.sut.syncManagedObjectContext)
    }

    func testThatLinkedUIContextIsNotStrongReferenced() {
        // given
        let mocSync: NSManagedObjectContext? = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        var mocUI: NSManagedObjectContext? = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)

        mocUI?.zm_sync = mocSync
        mocSync?.zm_userInterface = mocUI

        XCTAssertNotNil(mocUI?.zm_sync)
        XCTAssertNotNil(mocSync?.zm_userInterface)

        // when
        mocUI = nil

        // then
        XCTAssertNotNil(mocSync)
        XCTAssertNil(mocSync?.zm_userInterface)
    }

    func testThatLinkedSyncContextIsNotStrongReferenced() {
        // given
        var mocSync: NSManagedObjectContext? = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        let mocUI: NSManagedObjectContext? = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)

        mocUI?.zm_sync = mocSync
        mocSync?.zm_userInterface = mocUI

        XCTAssertNotNil(mocUI?.zm_sync)
        XCTAssertNotNil(mocSync?.zm_userInterface)

        // when
        mocSync = nil

        // then
        XCTAssertNotNil(mocUI)
        XCTAssertNil(mocUI?.zm_sync)
    }

    func testThatItNotfiesTheTransportSessionWhenSelfUserClientIsRegistered() {
        // given
        let userClient = syncMOC.performAndWait {
            self.createSelfClient()
        }

        // when
        sut.didRegisterSelfUserClient(userClient)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(mockPushChannel.clientID, userClient.remoteIdentifier)
    }

    func testThatPerformChangesAreDoneSynchronouslyOnTheMainQueue() {
        // given
        var executed: Bool = false
        var contextSaved: Bool = false

        // expect
        NotificationCenter.default.addObserver(forName: .NSManagedObjectContextDidSave, object: uiMOC, queue: nil) { _ in
            contextSaved = true
        }

        // when
        sut.perform {
            XCTAssertEqual(OperationQueue.current, OperationQueue.main)
            XCTAssertFalse(executed)
            XCTAssertFalse(contextSaved)
            executed = true
            ZMConversation.insertNewObject(in: self.uiMOC) // force a save
        }

        // then
        XCTAssertTrue(contextSaved)
        XCTAssertTrue(executed)
    }

    func testThatEnqueueChangesAreDoneAsynchronouslyOnTheMainQueue() {
        // given
        var executed = false
        var contextSaved = false

        // expect
        NotificationCenter.default.addObserver(forName: .NSManagedObjectContextDidSave, object: uiMOC, queue: nil) { _ in
            contextSaved = true
        }

        // when
        sut.enqueue {
            XCTAssertEqual(OperationQueue.current, OperationQueue.main)
            XCTAssertFalse(executed)
            XCTAssertFalse(contextSaved)
            executed = true
            ZMConversation.insertNewObject(in: self.uiMOC) // force a save
        }

        // then
        XCTAssertFalse(executed)
        XCTAssertFalse(contextSaved)

        // and when
        spinMainQueue(withTimeout: 0.05)

        // then
        XCTAssertTrue(contextSaved)
        XCTAssertTrue(executed)
    }

    func testThatEnqueueChangesAreDoneAsynchronouslyOnTheMainQueueWithCompletionHandler() {
        // given
        var executed = false
        var blockExecuted = false
        var contextSaved = false

        // expect
        NotificationCenter.default.addObserver(forName: .NSManagedObjectContextDidSave, object: uiMOC, queue: nil) { _ in
            contextSaved = true
        }

        // when
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

        // then
        XCTAssertFalse(executed)
        XCTAssertFalse(blockExecuted)
        XCTAssertFalse(contextSaved)

        // and when
        spinMainQueue(withTimeout: 0.05)

        // then
        XCTAssertTrue(executed)
        XCTAssertTrue(blockExecuted)
        XCTAssertTrue(contextSaved)
    }

    func testThatEnqueueDelayedChangesAreDoneAsynchronouslyOnTheMainQueueWithCompletionHandler() {
        // given
        var executed = false
        var blockExecuted = false
        var contextSaved = false

        // expect
        NotificationCenter.default.addObserver(forName: .NSManagedObjectContextDidSave, object: uiMOC, queue: nil) { _ in
            contextSaved = true
        }

        // when
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

        // then
        XCTAssertFalse(executed)
        XCTAssertFalse(blockExecuted)
        XCTAssertFalse(contextSaved)

        // and when
        spinMainQueue(withTimeout: 0.2) // the delayed save will wait 0.1 seconds

        // then
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
        // when
        sut.didGoOffline()
        sut.didReceiveData()

        // then
        XCTAssertTrue(waitForOnlineSynchronizingStatus())

    }

    func testThatWeSetUserSessionToOfflineWhenARequestFails() {
        // when
        sut.didGoOffline()

        // then
        XCTAssertTrue(waitForOfflineStatus())
    }

    func testThatItNotifiesThirdPartyServicesWhenSyncIsDone() {
        // given
        XCTAssertEqual(thirdPartyServices.uploadCount, 0)

        // when
        sut.didFinishQuickSync()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(thirdPartyServices.uploadCount, 1)
    }

    func testThatItOnlyNotifiesThirdPartyServicesOnce() {
        // given
        XCTAssertEqual(thirdPartyServices.uploadCount, 0)

        // when
        sut.didFinishQuickSync()
        sut.didStartQuickSync()
        sut.didFinishQuickSync()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(thirdPartyServices.uploadCount, 1)
    }

    func testThatItNotifiesThirdPartyServicesWhenEnteringBackground() {
        // given
        XCTAssertEqual(self.thirdPartyServices.uploadCount, 0)

        // when
        self.sut.applicationDidEnterBackground(nil)

        // then
        XCTAssertEqual(thirdPartyServices.uploadCount, 1)
    }

    func testThatItNotifiesThirdPartyServicesAgainAfterEnteringForeground_1() {
        // given
        XCTAssertEqual(thirdPartyServices.uploadCount, 0)

        // when
        sut.applicationDidEnterBackground(nil)
        sut.applicationWillEnterForeground(nil)
        sut.applicationDidEnterBackground(nil)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(thirdPartyServices.uploadCount, 2)
    }

    func testThatItNotifiesThirdPartyServicesAgainAfterEnteringForeground_2() {
        // given
        XCTAssertEqual(thirdPartyServices.uploadCount, 0)

        // when
        sut.didFinishQuickSync()
        sut.applicationDidEnterBackground(nil)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(thirdPartyServices.uploadCount, 1)

        sut.applicationWillEnterForeground(nil)
        sut.didStartQuickSync()
        sut.didFinishQuickSync()
        sut.applicationDidEnterBackground(nil)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(thirdPartyServices.uploadCount, 2)
    }

    func testThatWeDoNotSetUserSessionToSyncDoneWhenSyncIsDoneIfWeWereNotSynchronizing() {
        // when
        sut.didGoOffline()
        sut.didFinishQuickSync()

        // then
        XCTAssertTrue(waitForOfflineStatus())
    }

    func testThatWeSetUserSessionToSynchronizingWhenSyncIsStarted() {
        // when
        sut.didStartQuickSync()

        // then
        XCTAssertTrue(waitForOnlineSynchronizingStatus())
    }

    func testThatWeCanGoBackOnlineAfterGoingOffline() {
        // when
        sut.didGoOffline()

        // then
        XCTAssertTrue(waitForOfflineStatus())

        // when
        sut.didReceiveData()

        // then
        XCTAssertTrue(waitForOnlineSynchronizingStatus())

    }

    func testThatWeCanGoBackOfflineAfterGoingOnline() {
        // when
        sut.didGoOffline()

        // then
        XCTAssertTrue(waitForOfflineStatus())

        // when
        sut.didReceiveData()

        // then
        XCTAssertTrue(waitForOnlineSynchronizingStatus())

        // when
        sut.didGoOffline()

        // then
        XCTAssertTrue(waitForOfflineStatus())
    }

    func testThatItNotifiesObserversWhenTheNetworkStatusBecomesOnline() {
        // given
        let stateRecorder = NetworkStateRecorder()
        sut.didGoOffline()
        XCTAssertTrue(waitForOfflineStatus())
        XCTAssertEqual(sut.networkState, .offline)

        // when
        var token: Any? = ZMNetworkAvailabilityChangeNotification.addNetworkAvailabilityObserver(stateRecorder, userSession: sut)
        sut.didReceiveData()

        // then
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(stateRecorder.stateChanges.count, 1)
        XCTAssertEqual(stateRecorder.stateChanges.first, .onlineSynchronizing)
        token = nil
    }

    func testThatItDoesNotNotifiesObserversWhenTheNetworkStatusWasAlreadyOnline() {
        // given
        let stateRecorder = NetworkStateRecorder()

        // when
        var token: Any? = ZMNetworkAvailabilityChangeNotification.addNetworkAvailabilityObserver(stateRecorder, userSession: sut)
        sut.didReceiveData()

        // then
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(stateRecorder.stateChanges.count, 0)
        token = nil
    }

    func testThatItNotifiesObserversWhenTheNetworkStatusBecomesOffline() {
        // given
        let stateRecorder = NetworkStateRecorder()

        // when
        var token: Any? = ZMNetworkAvailabilityChangeNotification.addNetworkAvailabilityObserver(stateRecorder, userSession: sut)
        sut.didGoOffline()

        // then
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(stateRecorder.stateChanges.count, 1)
        XCTAssertEqual(stateRecorder.stateChanges.first, .offline)
        token = nil
    }

    func testThatItDoesNotNotifiesObserversWhenTheNetworkStatusWasAlreadyOffline() {
        // given
        let stateRecorder = NetworkStateRecorder()

        sut.didGoOffline()
        XCTAssertTrue(waitForOfflineStatus())

        // when
        var token: Any? = ZMNetworkAvailabilityChangeNotification.addNetworkAvailabilityObserver(stateRecorder, userSession: sut)
        sut.didGoOffline()

        // then
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(stateRecorder.stateChanges.count, 0)
        token = nil
    }

    func testThatItSetsTheMinimumBackgroundFetchInterval() {
        XCTAssertNotEqual(application.minimumBackgroundFetchInverval, UIApplication.backgroundFetchIntervalNever)
        XCTAssertGreaterThanOrEqual(application.minimumBackgroundFetchInverval, UIApplication.backgroundFetchIntervalMinimum)
        XCTAssertLessThanOrEqual(application.minimumBackgroundFetchInverval, (TimeInterval) (20 * 60))
    }

    func testThatItMarksTheConversationsAsRead() throws {
        // given
        let conversationsRange: CountableClosedRange = 1...10

        let conversations: [ZMConversation] = conversationsRange.map { _ in
            return self.sut.insertConversationWithUnreadMessage()
        }

        try self.uiMOC.save()

        // when
        self.sut.markAllConversationsAsRead()

        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        self.uiMOC.refreshAllObjects()
        XCTAssertEqual(conversations.filter { $0.firstUnreadMessage != nil }.count, 0)
    }

    func test_itPerformsPeriodicMLSUpdates_AfterQuickSync() {
        // given
        mockMLSService.performPendingJoins_MockMethod = {}
        mockMLSService.commitPendingProposals_MockMethod = {}
        mockMLSService.uploadKeyPackagesIfNeeded_MockMethod = {}
        mockMLSService.updateKeyMaterialForAllStaleGroupsIfNeeded_MockMethod = {}

        // MLS client has been registered
        self.syncMOC.performAndWait {
            let selfUserClient = createSelfClient()
            selfUserClient.mlsPublicKeys = UserClient.MLSPublicKeys(ed25519: "somekey")
            selfUserClient.needsToUploadMLSPublicKeys = false
            syncMOC.saveOrRollback()
        }

        // when
        sut.didFinishQuickSync()

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertFalse(mockMLSService.performPendingJoins_Invocations.isEmpty)
        XCTAssertFalse(mockMLSService.uploadKeyPackagesIfNeeded_Invocations.isEmpty)
        XCTAssertFalse(mockMLSService.updateKeyMaterialForAllStaleGroupsIfNeeded_Invocations.isEmpty)
    }
}
