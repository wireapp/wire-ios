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

import XCTest
@testable import WireSyncEngine

final class SyncStatusTests: MessagingTest {
    var sut: SyncStatus!
    var mockSyncDelegate: MockSyncStateDelegate!

    override func setUp() {
        super.setUp()
        mockSyncDelegate = MockSyncStateDelegate()
        sut = createSut()
    }

    override func tearDown() {
        mockSyncDelegate = nil
        sut = nil
        super.tearDown()
    }

    private func createSut() -> SyncStatus {
        let sut = SyncStatus(
            managedObjectContext: uiMOC,
            lastEventIDRepository: lastEventIDRepository
        )
        sut.syncStateDelegate = mockSyncDelegate
        return sut
    }

    func testThatWhenIntializingWithoutLastEventIDItStartsInStateFetchingLastUpdateEventID() {
        // given
        lastEventIDRepository.storeLastEventID(nil)

        // when
        sut.determineInitialSyncPhase()

        // then
        XCTAssertEqual(sut.currentSyncPhase, .fetchingLastUpdateEventID)
    }

    func testThatWhenIntializingWihtLastEventIDItStartsInStateFetchingMissingEvents() {
        // given
        lastEventIDRepository.storeLastEventID(UUID.timeBasedUUID() as UUID)

        // when
        sut.determineInitialSyncPhase()

        // then
        XCTAssertEqual(sut.currentSyncPhase, .fetchingMissedEvents)
    }

    func testThatItGoesThroughTheStatesInSpecificOrder() {
        // given
        var syncPhases = SyncPhase.allCases
        syncPhases.removeLast() // last phase is '.done' and can not be finished

        sut.determineInitialSyncPhase()

        for syncPhase in syncPhases {
            // then
            XCTAssertEqual(sut.currentSyncPhase, syncPhase)
            // when
            sut.finishCurrentSyncPhase(phase: syncPhase)
        }
        // then
        XCTAssertEqual(sut.currentSyncPhase, .done)
    }

    func testThatItSavesTheLastNotificationIDOnlyAfterFinishingUserPhase() {
        // given
        sut.determineInitialSyncPhase()
        XCTAssertEqual(sut.currentSyncPhase, .fetchingLastUpdateEventID)
        sut.updateLastUpdateEventID(eventID: UUID.timeBasedUUID() as UUID)
        XCTAssertNil(lastEventIDRepository.fetchLastEventID())

        // when
        sut.finishCurrentSyncPhase(phase: .fetchingLastUpdateEventID)
        // then
        XCTAssertNil(lastEventIDRepository.fetchLastEventID())
        // when
        sut.finishCurrentSyncPhase(phase: .fetchingTeams)
        // then
        XCTAssertNil(lastEventIDRepository.fetchLastEventID())
        // then
        sut.finishCurrentSyncPhase(phase: .fetchingTeamMembers)
        // then
        XCTAssertNil(lastEventIDRepository.fetchLastEventID())
        // when
        sut.finishCurrentSyncPhase(phase: .fetchingTeamRoles)
        // then
        XCTAssertNil(lastEventIDRepository.fetchLastEventID())
        // when
        sut.finishCurrentSyncPhase(phase: .fetchingConnections)
        // then
        XCTAssertNil(lastEventIDRepository.fetchLastEventID())
        // when
        sut.finishCurrentSyncPhase(phase: .fetchingConversations)
        // then
        XCTAssertNil(lastEventIDRepository.fetchLastEventID())
        XCTAssertEqual(sut.currentSyncPhase, .fetchingUsers)
        // when
        sut.finishCurrentSyncPhase(phase: .fetchingUsers)
        // then
        XCTAssertNil(lastEventIDRepository.fetchLastEventID())
        XCTAssertEqual(sut.currentSyncPhase, .fetchingSelfUser)
        // when
        sut.finishCurrentSyncPhase(phase: .fetchingSelfUser)
        // then
        XCTAssertNil(lastEventIDRepository.fetchLastEventID())
        // when
        sut.finishCurrentSyncPhase(phase: .fetchingLegalHoldStatus)
        // then
        XCTAssertNil(lastEventIDRepository.fetchLastEventID())
        // when
        sut.finishCurrentSyncPhase(phase: .fetchingLabels)
        // when
        sut.finishCurrentSyncPhase(phase: .fetchingFeatureConfig)
        // when
        sut.finishCurrentSyncPhase(phase: .updateSelfSupportedProtocols)
        // when
        sut.finishCurrentSyncPhase(phase: .evaluate1on1ConversationsForMLS)

        // then
        XCTAssertNotNil(lastEventIDRepository.fetchLastEventID())
    }

    func testThatItDoesNotSetTheLastNotificationIDIfItHasNone() {
        sut.determineInitialSyncPhase()
        XCTAssertEqual(sut.currentSyncPhase, .fetchingLastUpdateEventID)
        lastEventIDRepository.storeLastEventID(UUID.timeBasedUUID() as UUID)
        XCTAssertNotNil(lastEventIDRepository.fetchLastEventID())

        // when
        XCTAssertEqual(sut.currentSyncPhase, .fetchingLastUpdateEventID)
        // when
        sut.finishCurrentSyncPhase(phase: .fetchingLastUpdateEventID)
        // then
        XCTAssertEqual(sut.currentSyncPhase, .fetchingTeams)
        // when
        sut.finishCurrentSyncPhase(phase: .fetchingTeams)
        // then
        XCTAssertEqual(sut.currentSyncPhase, .fetchingTeamMembers)
        // when
        sut.finishCurrentSyncPhase(phase: .fetchingTeamMembers)
        // then
        XCTAssertEqual(sut.currentSyncPhase, .fetchingTeamRoles)
        // when
        sut.finishCurrentSyncPhase(phase: .fetchingTeamRoles)
        // then
        XCTAssertEqual(sut.currentSyncPhase, .fetchingConnections)
        // when
        sut.finishCurrentSyncPhase(phase: .fetchingConnections)
        // then
        XCTAssertEqual(sut.currentSyncPhase, .fetchingConversations)
        // when
        sut.finishCurrentSyncPhase(phase: .fetchingConversations)
        // then
        XCTAssertEqual(sut.currentSyncPhase, .fetchingUsers)
        // when
        sut.finishCurrentSyncPhase(phase: .fetchingUsers)
        // then
        XCTAssertEqual(sut.currentSyncPhase, .fetchingSelfUser)
        // when
        sut.finishCurrentSyncPhase(phase: .fetchingSelfUser)
        // then
        XCTAssertNotNil(lastEventIDRepository.fetchLastEventID())
    }

    func testThatItNotifiesTheStateDelegateWhenFinishingSync() {
        // given
        sut.determineInitialSyncPhase()
        XCTAssertEqual(sut.currentSyncPhase, .fetchingLastUpdateEventID)
        XCTAssertFalse(mockSyncDelegate.didCallFinishSlowSync)
        XCTAssertFalse(mockSyncDelegate.didCallFinishQuickSync)

        // when
        sut.finishCurrentSyncPhase(phase: .fetchingLastUpdateEventID)
        // then
        XCTAssertFalse(mockSyncDelegate.didCallFinishQuickSync)
        // when
        sut.finishCurrentSyncPhase(phase: .fetchingTeams)
        // then
        XCTAssertFalse(mockSyncDelegate.didCallFinishQuickSync)
        // when
        sut.finishCurrentSyncPhase(phase: .fetchingTeamMembers)
        // then
        XCTAssertFalse(mockSyncDelegate.didCallFinishQuickSync)
        // when
        sut.finishCurrentSyncPhase(phase: .fetchingTeamRoles)
        // then
        XCTAssertFalse(mockSyncDelegate.didCallFinishQuickSync)
        // when
        sut.finishCurrentSyncPhase(phase: .fetchingConnections)
        // then
        XCTAssertFalse(mockSyncDelegate.didCallFinishQuickSync)
        // when
        sut.finishCurrentSyncPhase(phase: .fetchingConversations)
        // then
        XCTAssertFalse(mockSyncDelegate.didCallFinishQuickSync)
        // when
        sut.finishCurrentSyncPhase(phase: .fetchingUsers)
        // then
        XCTAssertFalse(mockSyncDelegate.didCallFinishQuickSync)
        // when
        sut.finishCurrentSyncPhase(phase: .fetchingSelfUser)
        // when
        sut.finishCurrentSyncPhase(phase: .fetchingLegalHoldStatus)
        // when
        sut.finishCurrentSyncPhase(phase: .fetchingLabels)
        // when
        sut.finishCurrentSyncPhase(phase: .fetchingFeatureConfig)
        // when
        sut.finishCurrentSyncPhase(phase: .updateSelfSupportedProtocols)
        // when
        sut.finishCurrentSyncPhase(phase: .evaluate1on1ConversationsForMLS)
        // when
        sut.finishCurrentSyncPhase(phase: .fetchingMissedEvents)

        // then
        XCTAssertTrue(mockSyncDelegate.didCallFinishSlowSync)
        XCTAssertTrue(mockSyncDelegate.didCallFinishQuickSync)
    }

    func testThatItNotifiesTheStateDelegateWhenStartingSlowSync() {
        // when
        sut.determineInitialSyncPhase()

        // then
        XCTAssertTrue(mockSyncDelegate.didCallStartSlowSync)
    }

    func testThatItNotifiesTheStateDelegateWhenStartingQuickSync() {
        // given
        lastEventIDRepository.storeLastEventID(UUID.timeBasedUUID() as UUID)

        // when
        sut.determineInitialSyncPhase()

        // then
        XCTAssertEqual(sut.currentSyncPhase, .fetchingMissedEvents)
        XCTAssertTrue(mockSyncDelegate.didCallStartQuickSync)
    }

    func testThatItDoesNotNotifyTheStateDelegateWhenAlreadySyncing() {
        // given
        sut.determineInitialSyncPhase()
        mockSyncDelegate.didCallStartQuickSync = false
        sut.finishCurrentSyncPhase(phase: .fetchingLastUpdateEventID)
        XCTAssertEqual(sut.currentSyncPhase, .fetchingTeams)

        XCTAssertFalse(mockSyncDelegate.didCallStartQuickSync)

        // when
        sut.finishCurrentSyncPhase(phase: .fetchingTeams)

        // then
        XCTAssertFalse(mockSyncDelegate.didCallStartQuickSync)
    }

    func testThatItNotifiesTheStateDelegateWhenPushChannelClosedThatSyncStarted() {
        // given
        lastEventIDRepository.storeLastEventID(UUID.timeBasedUUID() as UUID)
        sut.determineInitialSyncPhase()
        sut.finishCurrentSyncPhase(phase: .fetchingMissedEvents)
        XCTAssertEqual(sut.currentSyncPhase, .done)
        mockSyncDelegate.didCallStartQuickSync = false

        // when
        sut.pushChannelDidClose()

        // then
        XCTAssertTrue(mockSyncDelegate.didCallStartQuickSync)
    }

    // MARK: - QuickSync

    func testThatItStartsQuickSyncWhenPushChannelOpens_PreviousPhaseDone() {
        // given
        lastEventIDRepository.storeLastEventID(UUID.timeBasedUUID() as UUID)
        sut.determineInitialSyncPhase()
        sut.finishCurrentSyncPhase(phase: .fetchingMissedEvents)
        XCTAssertEqual(sut.currentSyncPhase, .done)

        // when
        sut.pushChannelDidOpen()

        // then
        XCTAssertEqual(sut.currentSyncPhase, .fetchingMissedEvents)
    }

    func testThatItDoesNotStartsQuickSyncWhenPushChannelOpens_PreviousInSlowSync() {
        // given
        sut.determineInitialSyncPhase()
        XCTAssertEqual(sut.currentSyncPhase, .fetchingLastUpdateEventID)

        // when
        sut.pushChannelDidOpen()

        // then
        XCTAssertEqual(sut.currentSyncPhase, .fetchingLastUpdateEventID)
    }

    func testThatItRestartsQuickSyncWhenPushChannelWasOpenedAfterNotificationFetchBegan() {
        // given
        lastEventIDRepository.storeLastEventID(UUID.timeBasedUUID() as UUID)
        sut.pushChannelDidOpen()
        sut.determineInitialSyncPhase()
        XCTAssertEqual(sut.currentSyncPhase, .fetchingMissedEvents)
        XCTAssertFalse(sut.needsToRestartQuickSync)

        // when
        let beforePushChannelEstablished = sut.pushChannelEstablishedDate?.addingTimeInterval(-.oneSecond)
        sut.completedFetchingNotificationStream(fetchBeganAt: beforePushChannelEstablished)

        // then
        XCTAssertEqual(sut.currentSyncPhase, .fetchingMissedEvents)
    }

    func testThatItRestartsQuickSyncWhenPushChannelOpens_PreviousInQuickSync() {
        // given
        lastEventIDRepository.storeLastEventID(UUID.timeBasedUUID() as UUID)
        sut.determineInitialSyncPhase()
        XCTAssertEqual(sut.currentSyncPhase, .fetchingMissedEvents)
        XCTAssertFalse(sut.needsToRestartQuickSync)

        // when
        sut.pushChannelDidOpen()

        // then
        XCTAssertEqual(sut.currentSyncPhase, .fetchingMissedEvents)
        XCTAssertTrue(sut.needsToRestartQuickSync)

        // and when
        sut.finishCurrentSyncPhase(phase: .fetchingMissedEvents)

        // then
        XCTAssertEqual(sut.currentSyncPhase, .fetchingMissedEvents)
    }

    func testThatItRestartsQuickSyncWhenPushChannelClosedDuringQuickSync() {
        // given
        lastEventIDRepository.storeLastEventID(UUID.timeBasedUUID() as UUID)
        sut.determineInitialSyncPhase()
        XCTAssertEqual(sut.currentSyncPhase, .fetchingMissedEvents)
        XCTAssertFalse(sut.needsToRestartQuickSync)

        // when
        sut.pushChannelDidOpen()

        // then
        XCTAssertEqual(sut.currentSyncPhase, .fetchingMissedEvents)
        XCTAssertTrue(sut.needsToRestartQuickSync)

        // and when
        sut.pushChannelDidClose()
        sut.pushChannelDidOpen()
        sut.finishCurrentSyncPhase(phase: .fetchingMissedEvents)

        // then
        XCTAssertEqual(sut.currentSyncPhase, .fetchingMissedEvents)
    }

    func testThatItRestartsSlowSyncWhenRestartSlowSyncIsCalled() {
        // given
        lastEventIDRepository.storeLastEventID(UUID.timeBasedUUID() as UUID)
        sut.determineInitialSyncPhase()
        sut.finishCurrentSyncPhase(phase: .fetchingMissedEvents)
        XCTAssertEqual(sut.currentSyncPhase, .done)

        // when
        sut.forceSlowSync()

        // then
        XCTAssertEqual(sut.currentSyncPhase, .fetchingLastUpdateEventID)
        XCTAssertTrue(sut.isSyncing)
    }

    func testThatItRestartsSlowSyncWhenRestartSlowSyncNotificationIsFired() {
        // given
        lastEventIDRepository.storeLastEventID(UUID.timeBasedUUID() as UUID)
        sut.determineInitialSyncPhase()
        sut.finishCurrentSyncPhase(phase: .fetchingMissedEvents)
        XCTAssertEqual(sut.currentSyncPhase, .done)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        NotificationInContext(name: .resyncResources, context: uiMOC.notificationContext).post()

        // then
        XCTAssertEqual(sut.currentSyncPhase, .fetchingTeams)
        XCTAssertTrue(sut.isSyncing)
    }

    func testThatItDoesNotRestartsQuickSyncWhenPushChannelIsClosed() {
        // given
        lastEventIDRepository.storeLastEventID(UUID.timeBasedUUID() as UUID)
        sut.determineInitialSyncPhase()
        XCTAssertEqual(sut.currentSyncPhase, .fetchingMissedEvents)
        XCTAssertFalse(sut.needsToRestartQuickSync)

        // when
        sut.pushChannelDidOpen()

        // then
        XCTAssertEqual(sut.currentSyncPhase, .fetchingMissedEvents)
        XCTAssertTrue(sut.needsToRestartQuickSync)

        // and when
        sut.pushChannelDidClose()
        sut.finishCurrentSyncPhase(phase: .fetchingMissedEvents)

        // then
        XCTAssertEqual(sut.currentSyncPhase, .done)
    }

    func testThatItEntersSlowSyncIfQuickSyncFailed() {
        // given
        lastEventIDRepository.storeLastEventID(UUID.timeBasedUUID() as UUID)
        sut.determineInitialSyncPhase()
        XCTAssertEqual(sut.currentSyncPhase, .fetchingMissedEvents)

        // when
        sut.failCurrentSyncPhase(phase: .fetchingMissedEvents)

        // then
        XCTAssertEqual(sut.currentSyncPhase, .fetchingLastUpdateEventID)
    }

    func testThatItClearsLastNotificationIDWhenQuickSyncFails() {
        // given
        let oldID = UUID.timeBasedUUID() as UUID
        let newID = UUID.timeBasedUUID() as UUID
        lastEventIDRepository.storeLastEventID(oldID)
        sut.determineInitialSyncPhase()
        XCTAssertEqual(sut.currentSyncPhase, .fetchingMissedEvents)

        // when
        sut.updateLastUpdateEventID(eventID: newID)
        sut.failCurrentSyncPhase(phase: .fetchingMissedEvents)

        // then
        XCTAssertNil(lastEventIDRepository.fetchLastEventID())
    }

    func testThatItSavesLastNotificationIDOnlyAfterSlowSyncFinishedSuccessfullyAfterFailedQuickSync() {
        // given
        let oldID = UUID.timeBasedUUID() as UUID
        let newID = UUID.timeBasedUUID() as UUID
        lastEventIDRepository.storeLastEventID(oldID)
        sut.determineInitialSyncPhase()
        XCTAssertEqual(sut.currentSyncPhase, .fetchingMissedEvents)

        // when
        sut.updateLastUpdateEventID(eventID: newID)
        sut.failCurrentSyncPhase(phase: .fetchingMissedEvents)

        // then
        XCTAssertNotEqual(lastEventIDRepository.fetchLastEventID(), newID)
        XCTAssertEqual(sut.currentSyncPhase, .fetchingLastUpdateEventID)

        // and when
        sut.finishCurrentSyncPhase(phase: .fetchingLastUpdateEventID)
        // then
        sut.finishCurrentSyncPhase(phase: .fetchingTeams)
        // then
        XCTAssertNotEqual(lastEventIDRepository.fetchLastEventID(), newID)
        // when
        sut.finishCurrentSyncPhase(phase: .fetchingTeamMembers)
        // then
        XCTAssertNotEqual(lastEventIDRepository.fetchLastEventID(), newID)
        // when
        sut.finishCurrentSyncPhase(phase: .fetchingTeamRoles)
        // then
        XCTAssertNotEqual(lastEventIDRepository.fetchLastEventID(), newID)
        // when
        sut.finishCurrentSyncPhase(phase: .fetchingConnections)
        // then
        XCTAssertNotEqual(lastEventIDRepository.fetchLastEventID(), newID)
        // when
        sut.finishCurrentSyncPhase(phase: .fetchingConversations)
        // then
        XCTAssertNotEqual(lastEventIDRepository.fetchLastEventID(), newID)
        // when
        XCTAssertEqual(sut.currentSyncPhase, .fetchingUsers)
        sut.finishCurrentSyncPhase(phase: .fetchingUsers)
        // when
        XCTAssertEqual(sut.currentSyncPhase, .fetchingSelfUser)
        sut.finishCurrentSyncPhase(phase: .fetchingSelfUser)
        // when
        XCTAssertEqual(sut.currentSyncPhase, .fetchingLegalHoldStatus)
        sut.finishCurrentSyncPhase(phase: .fetchingLegalHoldStatus)
        // when
        XCTAssertEqual(sut.currentSyncPhase, .fetchingLabels)
        sut.finishCurrentSyncPhase(phase: .fetchingLabels)
        // when
        XCTAssertEqual(sut.currentSyncPhase, .fetchingFeatureConfig)
        sut.finishCurrentSyncPhase(phase: .fetchingFeatureConfig)
        // when
        XCTAssertEqual(sut.currentSyncPhase, .updateSelfSupportedProtocols)
        sut.finishCurrentSyncPhase(phase: .updateSelfSupportedProtocols)
        // when
        XCTAssertEqual(sut.currentSyncPhase, .evaluate1on1ConversationsForMLS)
        sut.finishCurrentSyncPhase(phase: .evaluate1on1ConversationsForMLS)

        // then
        XCTAssertEqual(lastEventIDRepository.fetchLastEventID(), newID)
        XCTAssertNotEqual(lastEventIDRepository.fetchLastEventID(), oldID)
    }
}
