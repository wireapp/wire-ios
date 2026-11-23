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

import WireCoreCrypto
import WireDataModel
import WireDataModelSupport
import WireSystem
import XCTest

@testable import WireDomain

final class ProteusSessionRepairSchedulerTests: XCTestCase {

    private var stack: CoreDataStack!
    private var coreDataStackHelper: CoreDataStackHelper!
    private var modelHelper: ModelHelper!
    private var journal: Journal!
    private var currentDate = Date(timeIntervalSince1970: 1_784_628_000)

    private let senderUserID = UUID()
    private let senderClientID = "abcdef0123"
    private let brokenSessionError = ProteusService.DecryptionError.failedToDecryptData(.Other(errorCode: 406))

    private var context: NSManagedObjectContext {
        stack.syncContext
    }

    override func setUp() async throws {
        coreDataStackHelper = CoreDataStackHelper()
        modelHelper = ModelHelper()
        stack = try await coreDataStackHelper.createStack()
        journal = Journal(userID: UUID(), storage: UserDefaults.temporary())

        await context.perform { [self] in
            let sender = modelHelper.createUser(id: senderUserID, domain: "example.com", in: context)
            modelHelper.createClient(id: senderClientID, for: sender)
        }
    }

    override func tearDown() async throws {
        stack = nil
        try coreDataStackHelper.cleanupDirectory()
        coreDataStackHelper = nil
        modelHelper = nil
        journal = nil
    }

    private func makeSUT() -> ProteusSessionRepairScheduler {
        ProteusSessionRepairScheduler(
            journal: journal,
            context: context,
            minimumInterval: 60,
            now: { [unowned self] in currentDate }
        )
    }

    private func isRepairScheduled() async -> Bool {
        await context.perform { [self] in
            UserClient.fetchExistingUserClient(with: senderClientID, in: context)?
                .needsToNotifyOtherUserAboutSessionReset ?? false
        }
    }

    private func clearRepairFlag() async {
        await context.perform { [self] in
            UserClient.fetchExistingUserClient(with: senderClientID, in: context)?
                .needsToNotifyOtherUserAboutSessionReset = false
        }
    }

    // MARK: - Tests

    func testItSchedulesRepair_WhenSessionIsBroken() async {
        // When
        await makeSUT().scheduleRepairIfNeeded(
            for: brokenSessionError,
            senderUserID: senderUserID,
            senderClientID: senderClientID
        )

        // Then
        let isScheduled = await isRepairScheduled()
        XCTAssertTrue(isScheduled)
    }

    func testItSchedulesRepair_ForInvalidMessageError() async {
        // When
        await makeSUT().scheduleRepairIfNeeded(
            for: .failedToDecryptData(.Other(errorCode: 202)),
            senderUserID: senderUserID,
            senderClientID: senderClientID
        )

        // Then
        let isScheduled = await isRepairScheduled()
        XCTAssertTrue(isScheduled)
    }

    func testItDoesNotScheduleRepair_ForErrorsThatAreNotABrokenSession() async {
        let errors: [ProteusService.DecryptionError] = [
            .failedToDecryptData(.DuplicateMessage),
            .failedToDecryptData(.RemoteIdentityChanged),
            .failedToDecryptData(.Other(errorCode: 101)),
            .failedToEstablishSessionFromMessage(.Other(errorCode: 406))
        ]

        for error in errors {
            // When
            await makeSUT().scheduleRepairIfNeeded(
                for: error,
                senderUserID: senderUserID,
                senderClientID: senderClientID
            )

            // Then
            let isScheduled = await isRepairScheduled()
            XCTAssertFalse(isScheduled, "Unexpected repair for \(error)")
        }
    }

    func testItSchedulesRepairOncePerInterval() async {
        // Given
        let sut = makeSUT()
        await sut.scheduleRepairIfNeeded(
            for: brokenSessionError,
            senderUserID: senderUserID,
            senderClientID: senderClientID
        )
        await clearRepairFlag()

        // When: another failure within the interval
        currentDate += 59
        await sut.scheduleRepairIfNeeded(
            for: brokenSessionError,
            senderUserID: senderUserID,
            senderClientID: senderClientID
        )

        // Then
        let isScheduledWithinInterval = await isRepairScheduled()
        XCTAssertFalse(isScheduledWithinInterval)

        // When: another failure after the interval
        currentDate += 2
        await sut.scheduleRepairIfNeeded(
            for: brokenSessionError,
            senderUserID: senderUserID,
            senderClientID: senderClientID
        )

        // Then
        let isScheduledAfterInterval = await isRepairScheduled()
        XCTAssertTrue(isScheduledAfterInterval)
    }

    func testItLimitsRepairsAcrossSchedulerInstances() async {
        // Given: a previous app session scheduled a repair (the limit is persisted in the journal)
        await makeSUT().scheduleRepairIfNeeded(
            for: brokenSessionError,
            senderUserID: senderUserID,
            senderClientID: senderClientID
        )
        await clearRepairFlag()

        // When
        await makeSUT().scheduleRepairIfNeeded(
            for: brokenSessionError,
            senderUserID: senderUserID,
            senderClientID: senderClientID
        )

        // Then
        let isScheduled = await isRepairScheduled()
        XCTAssertFalse(isScheduled)
    }

    func testItSchedulesRepair_WhenTheLastAttemptIsInTheFuture() async {
        // Given: an attempt recorded before the clock was set back
        await makeSUT().scheduleRepairIfNeeded(
            for: brokenSessionError,
            senderUserID: senderUserID,
            senderClientID: senderClientID
        )
        await clearRepairFlag()

        // When
        currentDate -= 1
        await makeSUT().scheduleRepairIfNeeded(
            for: brokenSessionError,
            senderUserID: senderUserID,
            senderClientID: senderClientID
        )

        // Then
        let isScheduled = await isRepairScheduled()
        XCTAssertTrue(isScheduled)
    }

    func testItDoesNotScheduleRepair_WhenClientBelongsToAnotherUser() async {
        // When
        await makeSUT().scheduleRepairIfNeeded(
            for: brokenSessionError,
            senderUserID: UUID(),
            senderClientID: senderClientID
        )

        // Then
        let isScheduled = await isRepairScheduled()
        XCTAssertFalse(isScheduled)
        XCTAssertNil(journal[.proteusSessionRepairAttempts])
    }

}
