//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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
    var lastEventIDRepository: LastEventIDRepository!

    override func setUp() {
        super.setUp()
        mockSyncDelegate = MockSyncStateDelegate()
        lastEventIDRepository = LastEventIDRepository(userID: userIdentifier)
        sut = createSut()
    }

    override func tearDown() {
        lastEventIDRepository.storeLastEventID(nil)
        lastEventIDRepository = nil
        mockSyncDelegate = nil
        sut = nil
        super.tearDown()
    }

    private func createSut() -> SyncStatus {
        return SyncStatus(
            managedObjectContext: uiMOC,
            syncStateDelegate: mockSyncDelegate,
            lastEventIDRepository: lastEventIDRepository
        )
    }

    func testThatWhenIntializingWithoutLastEventIDItStartsInStateFetchingLastUpdateEventID() {
        // given
        lastEventIDRepository.storeLastEventID(nil)

        // when
        sut = createSut()

        // then
        XCTAssertEqual(sut.currentSyncPhase, .fetchingLastUpdateEventID)
    }

    func testThatWhenIntializingWihtLastEventIDItStartsInStateFetchingMissingEvents() {
        // given
        lastEventIDRepository.storeLastEventID(UUID.timeBasedUUID() as UUID)

        // when
        sut = createSut()

        // then
        XCTAssertEqual(sut.currentSyncPhase, .fetchingMissedEvents)
    }

    private var syncPhases: [SyncPhase] {
        return [.fetchingLastUpdateEventID,
                .fetchingTeams,
                .fetchingTeamMembers,
                .fetchingTeamRoles,
                .fetchingConnections,
                .fetchingConversations,
                .fetchingUsers,
                .fetchingSelfUser,
                .fetchingLegalHoldStatus,
                .fetchingLabels,
                .fetchingMissedEvents]
    }

    func testThatItGoesThroughTheStatesInSpecificOrder() {
        syncPhases.forEach { syncPhase in
            // given / then
            XCTAssertEqual(sut.currentSyncPhase, syncPhase)
            // when
            sut.finishCurrentSyncPhase(phase: syncPhase)
        }
        // then
        XCTAssertEqual(sut.currentSyncPhase, .done)
    }

    func testThatItSavesTheLastNotificationIDOnlyAfterFinishingUserPhase() {
        // given
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
        // when
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

        // then
        XCTAssertNotNil(lastEventIDRepository.fetchLastEventID())

    }

    func testThatItDoesNotSetTheLastNotificationIDIfItHasNone() {
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
        sut.finishCurrentSyncPhase(phase: .fetchingMissedEvents)

        // then
        XCTAssertTrue(mockSyncDelegate.didCallFinishSlowSync)
        XCTAssertTrue(mockSyncDelegate.didCallFinishQuickSync)
    }

    func testThatItNotifiesTheStateDelegateWhenStartingSlowSync() {
        // given
        sut = createSut()
        XCTAssertEqual(sut.currentSyncPhase, .fetchingLastUpdateEventID)

        // then
        XCTAssertTrue(mockSyncDelegate.didCallStartSlowSync)
    }

    func testThatItNotifiesTheStateDelegateWhenStartingQuickSync() {
        // given
        lastEventIDRepository.storeLastEventID(UUID.timeBasedUUID() as UUID)
        sut = createSut()
        XCTAssertEqual(sut.currentSyncPhase, .fetchingMissedEvents)

        // then
        XCTAssertTrue(mockSyncDelegate.didCallStartQuickSync)
    }

    func testThatItDoesNotNotifyTheStateDelegateWhenAlreadySyncing() {
        // given
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
        sut = createSut()
        sut.finishCurrentSyncPhase(phase: .fetchingMissedEvents)
        XCTAssertEqual(sut.currentSyncPhase, .done)
        mockSyncDelegate.didCallStartQuickSync = false

        // when
        sut.pushChannelDidClose()

        // then
        XCTAssertTrue(mockSyncDelegate.didCallStartQuickSync)

    }

}

// MARK: QuickSync
extension SyncStatusTests {

    func testThatItStartsQuickSyncWhenPushChannelOpens_PreviousPhaseDone() {
        // given
        lastEventIDRepository.storeLastEventID(UUID.timeBasedUUID() as UUID)
        sut = createSut()
        sut.finishCurrentSyncPhase(phase: .fetchingMissedEvents)
        XCTAssertEqual(sut.currentSyncPhase, .done)

        // when
        sut.pushChannelDidOpen()

        // then
        XCTAssertEqual(sut.currentSyncPhase, .fetchingMissedEvents)
    }

    func testThatItDoesNotStartsQuickSyncWhenPushChannelOpens_PreviousInSlowSync() {
        // given
        XCTAssertEqual(sut.currentSyncPhase, .fetchingLastUpdateEventID)

        // when
        sut.pushChannelDidOpen()

        // then
        XCTAssertEqual(sut.currentSyncPhase, .fetchingLastUpdateEventID)
    }

    func testThatItRestartsQuickSyncWhenPushChannelOpens_PreviousInQuickSync() {
        // given
        lastEventIDRepository.storeLastEventID(UUID.timeBasedUUID() as UUID)
        sut = createSut()
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
        sut = createSut()
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
        sut = createSut()
        sut.finishCurrentSyncPhase(phase: .fetchingMissedEvents)
        XCTAssertEqual(sut.currentSyncPhase, .done)

        // when
        sut.forceSlowSync()

        // then
        XCTAssertEqual(sut.currentSyncPhase, .fetchingTeams)
        XCTAssertTrue(sut.isSyncing)
    }

    func testThatItRestartsSlowSyncWhenRestartSlowSyncNotificationIsFired() {
        // given
        lastEventIDRepository.storeLastEventID(UUID.timeBasedUUID() as UUID)
        sut = createSut()
        sut.finishCurrentSyncPhase(phase: .fetchingMissedEvents)
        XCTAssertEqual(sut.currentSyncPhase, .done)
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        NotificationInContext(name: .ForceSlowSync, context: uiMOC.notificationContext).post()

        // then
        XCTAssertEqual(sut.currentSyncPhase, .fetchingTeams)
        XCTAssertTrue(sut.isSyncing)
    }

    func testThatItDoesNotRestartsQuickSyncWhenPushChannelIsClosed() {
        // given
        lastEventIDRepository.storeLastEventID(UUID.timeBasedUUID() as UUID)
        sut = createSut()
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
        sut = createSut()
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
        sut = createSut()
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
        sut = createSut()
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

        // then
        XCTAssertEqual(lastEventIDRepository.fetchLastEventID(), newID)
        XCTAssertNotEqual(lastEventIDRepository.fetchLastEventID(), oldID)
    }
}
