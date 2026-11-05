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

import Foundation
import Testing

@testable import WireMessagingAssembly
@testable import WireMessagingData
@testable import WireMessagingDomain
@testable import WireMessagingDomainSupport

struct WireDriveDirectUploadSessionHolderTests {

    // MARK: - Singleton invariant

    /// Creating a second `URLSession` for a live background identifier is undefined behaviour, so the
    /// registry caching sessions is the mechanism's core safety property, not an optimisation.
    @Test
    func createsExactlyOneSessionPerUser() {
        // Given
        let created = Counter()
        let sut = makeSut(created: created)
        let userID = UUID()

        // When
        let first = sut.session(userID: userID)
        let second = sut.session(userID: userID)

        // Then
        #expect(created.value == 1)
        #expect(first.identifier == second.identifier)
    }

    @Test
    func createsADistinctSessionPerUser() {
        // Given
        let created = Counter()
        let sut = makeSut(created: created)

        // When
        _ = sut.session(userID: UUID())
        _ = sut.session(userID: UUID())

        // Then
        #expect(created.value == 2)
    }

    @Test
    func namesTheSessionAfterTheUser() {
        // Given
        let sut = makeSut()
        let userID = UUID()

        // Then
        #expect(sut.session(userID: userID).identifier == WireDriveDirectUploadSessionHolder.Identifier
            .make(userID: userID))
    }

    // MARK: - Claiming background launch events

    @Test
    func claimsItsOwnSessionEvents() {
        // Given
        let sut = makeSut()
        let identifier = WireDriveDirectUploadSessionHolder.Identifier.make(userID: UUID())

        // When
        let claimed = sut.handleEventsForBackgroundURLSession(identifier: identifier) {}

        // Then
        #expect(claimed)
    }

    /// Transport background sessions must keep reaching their own owner.
    @Test
    func doesNotClaimForeignSessionEvents() {
        // Given
        let sut = makeSut()

        // When
        let claimed = sut.handleEventsForBackgroundURLSession(identifier: "background-session") {}

        // Then
        #expect(!claimed)
    }

    /// Instantiating the session is what causes iOS to deliver the queued callbacks.
    @Test
    func createsTheSessionWhenClaimingEvents() {
        // Given
        let created = Counter()
        let sut = makeSut(created: created)

        // When
        _ = sut
            .handleEventsForBackgroundURLSession(identifier: WireDriveDirectUploadSessionHolder.Identifier
                .make(userID: UUID())) {}

        // Then
        #expect(created.value == 1)
    }

    @Test
    func doesNotCallTheCompletionHandlerBeforeTheSessionDrains() {
        // Given
        let sut = makeSut()
        let called = Counter()

        // When
        _ = sut
            .handleEventsForBackgroundURLSession(identifier: WireDriveDirectUploadSessionHolder.Identifier
                .make(userID: UUID())) {
                    called.increment()
            }

        // Then
        #expect(called.value == 0)
    }

    @Test
    @MainActor
    func callsTheCompletionHandlerOnceTheSessionHasDrained() async {
        // Given
        let sut = makeSut()
        let identifier = WireDriveDirectUploadSessionHolder.Identifier.make(userID: UUID())
        let called = Counter()
        _ = sut.handleEventsForBackgroundURLSession(identifier: identifier) { called.increment() }

        // When
        sut.didFinishEvents(identifier: identifier)
        await Task.yield()

        // Then
        #expect(called.value == 1)
    }

    /// iOS hands the handler over once; calling it twice traps.
    @Test
    @MainActor
    func callsTheCompletionHandlerAtMostOnce() async {
        // Given
        let sut = makeSut()
        let identifier = WireDriveDirectUploadSessionHolder.Identifier.make(userID: UUID())
        let called = Counter()
        _ = sut.handleEventsForBackgroundURLSession(identifier: identifier) { called.increment() }

        // When
        sut.didFinishEvents(identifier: identifier)
        sut.didFinishEvents(identifier: identifier)
        await Task.yield()

        // Then
        #expect(called.value == 1)
    }

    @Test
    @MainActor
    func ignoresDrainingForAnUnclaimedIdentifier() async {
        // Given
        let sut = makeSut()

        // When / Then — must not trap.
        sut.didFinishEvents(identifier: "never-claimed")
        await Task.yield()
    }

    @Test
    @MainActor
    func keepsInactiveAccountActivitiesUpdatingUntilTearDown() async {
        let sut = makeSut()
        let firstUserID = UUID()
        let secondUserID = UUID()
        let firstTracker = WireDriveObserveDirectUploadsUseCase()
        let secondTracker = WireDriveObserveDirectUploadsUseCase()
        let firstClient = FakeUploadsActivityClient()
        let secondClient = FakeUploadsActivityClient()
        var firstController: WireDriveUploadsLiveActivityController? = .init(
            observeUploads: firstTracker,
            client: firstClient,
            throttle: .init(minimumProgressInterval: 0)
        )
        var secondController: WireDriveUploadsLiveActivityController? = .init(
            observeUploads: secondTracker,
            client: secondClient
        )
        weak var retainedFirst = firstController
        weak var retainedSecond = secondController
        sut.retainLiveActivityController(firstController!, userID: firstUserID)
        sut.retainLiveActivityController(secondController!, userID: secondUserID)
        firstController?.start()
        secondController?.start()

        firstTracker.replaceAll(with: [.fixture(.uploading(progress: 0))])
        secondTracker.replaceAll(with: [.fixture(.queued)])
        await firstController?.endActivityIfNoUploads()
        await secondController?.endActivityIfNoUploads()

        // Releasing the UI's references must not stop either account's observation.
        firstController = nil
        secondController = nil
        #expect(retainedFirst != nil)
        #expect(retainedSecond != nil)

        firstTracker.replaceAll(with: [.fixture(.uploading(progress: 0.5))])
        await retainedFirst?.endActivityIfNoUploads()
        #expect(firstClient.calls.last == .update(.fixture(total: 1, progress: 0.5, showAccountName: true)))

        firstTracker.replaceAll(with: [.fixture(.uploaded)])
        await retainedFirst?.endActivityIfNoUploads()
        #expect(firstClient.calls.last == .update(.fixture(
            .completed,
            total: 1,
            uploaded: 1,
            progress: 1,
            showAccountName: true
        )))

        await sut.tearDown(userID: firstUserID)
        #expect(firstClient.calls.last == .endAll)
        #expect(retainedFirst == nil)
        #expect(retainedSecond != nil)
        #expect(secondClient.hasActivity)

        await sut.tearDown(userID: secondUserID)
        #expect(secondClient.calls.last == .endAll)
        #expect(retainedSecond == nil)
    }

    @Test
    @MainActor
    func showsAccountNamesOnlyWhileMultipleAccountsHaveActivities() async {
        let sut = makeSut()
        let firstTracker = WireDriveObserveDirectUploadsUseCase()
        let secondTracker = WireDriveObserveDirectUploadsUseCase()
        let firstClient = FakeUploadsActivityClient()
        let secondClient = FakeUploadsActivityClient()
        let delay = UploadsDelayGate()
        let first = WireDriveUploadsLiveActivityController(observeUploads: firstTracker, client: firstClient)
        let second = WireDriveUploadsLiveActivityController(
            observeUploads: secondTracker,
            client: secondClient,
            delay: { _ in await delay.wait() }
        )
        sut.retainLiveActivityController(first, userID: UUID())
        sut.retainLiveActivityController(second, userID: UUID())
        first.start()
        second.start()

        firstTracker.replaceAll(with: [.fixture(.queued)])
        await first.endActivityIfNoUploads()
        #expect(firstClient.calls.last == .start(.fixture(total: 1)))

        secondTracker.replaceAll(with: [.fixture(.queued)])
        await second.endActivityIfNoUploads()
        await first.endActivityIfNoUploads()
        await second.endActivityIfNoUploads()
        #expect(firstClient.calls.last == .update(.fixture(total: 1, showAccountName: true)))
        #expect(secondClient.calls.last == .update(.fixture(total: 1, showAccountName: true)))

        secondTracker.replaceAll(with: [.fixture(.uploaded)])
        await second.endActivityIfNoUploads()
        await delay.open()
        for _ in 0 ..< 20 {
            await Task.yield()
        }
        await first.endActivityIfNoUploads()
        #expect(!secondClient.hasActivity)
        #expect(firstClient.calls.last == .update(.fixture(total: 1)))

        await first.stop()
        await second.stop()
    }

    // MARK: - Tear down

    @Test
    func tearDownCancelsAndInvalidatesTheSession() async {
        // Given
        let session = MockWireDriveDirectUploadSessionProtocol()
        session.cancelAllTasks_MockMethod = {}
        session.invalidate_MockMethod = {}
        let sut = makeSut(session: session)
        let userID = UUID()
        _ = sut.session(userID: userID)

        // When
        await sut.tearDown(userID: userID)

        // Then
        #expect(session.cancelAllTasks_Invocations.count == 1)
        #expect(session.invalidate_Invocations.count == 1)
    }

    /// After tearing down, the next request must build a fresh session rather than hand back an
    /// invalidated one.
    @Test
    func createsAFreshSessionAfterTearDown() async {
        // Given
        let created = Counter()
        let session = MockWireDriveDirectUploadSessionProtocol()
        session.cancelAllTasks_MockMethod = {}
        session.invalidate_MockMethod = {}
        let sut = makeSut(session: session, created: created)
        let userID = UUID()
        _ = sut.session(userID: userID)

        // When
        await sut.tearDown(userID: userID)
        _ = sut.session(userID: userID)

        // Then
        #expect(created.value == 2)
    }

    @Test
    func tearDownForAnUnknownUserIsHarmless() async {
        // Given
        let session = MockWireDriveDirectUploadSessionProtocol()
        let sut = makeSut(session: session)

        // When
        await sut.tearDown(userID: UUID())

        // Then
        #expect(session.invalidate_Invocations.isEmpty)
    }

    // MARK: - Helpers

    private func makeSut(
        session: MockWireDriveDirectUploadSessionProtocol? = nil,
        created: Counter = Counter()
    ) -> WireDriveDirectUploadSessionHolder {
        WireDriveDirectUploadSessionHolder(
            sharedContainerIdentifier: "group.com.wire.test",
            makeSession: { identifier, _ in
                created.increment()
                let session = session ?? MockWireDriveDirectUploadSessionProtocol()
                session.identifier = identifier
                return session
            }
        )
    }

    private final class Counter: @unchecked Sendable {
        private let lock = NSLock()
        private var count = 0

        var value: Int {
            lock.withLock { count }
        }

        func increment() {
            lock.withLock { count += 1 }
        }
    }

    private final class SpySink: WireDriveDirectUploadEventSink {
        func handle(_ events: [WireDriveDirectUploadSessionEvent]) async {}
    }
}
