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

    // MARK: - Attaching

    @Test
    func routesEventsToTheSink() async {
        // Given
        let session = MockWireDriveDirectUploadSessionProtocol()
        session.setEventSink_MockMethod = { _ in }
        let sut = makeSut(session: session)
        let sink = SpySink()

        // When
        await sut.attach(userID: UUID(), sink: sink)

        // Then
        #expect(session.setEventSink_Invocations.count == 1)
    }

    @Test
    func stopsRoutingEventsOnDetach() async {
        // Given
        let session = MockWireDriveDirectUploadSessionProtocol()
        session.setEventSink_MockMethod = { _ in }
        session.removeEventSink_MockMethod = {}
        let sut = makeSut(session: session)
        let userID = UUID()
        await sut.attach(userID: userID, sink: SpySink())

        // When
        await sut.detach(userID: userID)

        // Then
        #expect(session.removeEventSink_Invocations.count == 1)
    }

    @Test
    func detachingAnUnknownUserIsHarmless() async {
        // Given
        let session = MockWireDriveDirectUploadSessionProtocol()
        let sut = makeSut(session: session)

        // When
        await sut.detach(userID: UUID())

        // Then
        #expect(session.removeEventSink_Invocations.isEmpty)
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
