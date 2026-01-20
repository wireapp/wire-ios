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
import Testing

import WireDomainSupport
@testable import WireDomain

@Suite("GeneratorsDirectory")
struct GeneratorsDirectoryTests {

    // MARK: - Helpers

    /// Awaits the first time `block` is executed (used to reliably observe async `.start()` calls triggered from a
    /// `Task { }`).
    private func waitForCall(_ installHandler: (@escaping () -> Void) -> Void) async {
        await withCheckedContinuation { (c: CheckedContinuation<Void, Never>) in
            installHandler { c.resume() }
        }
    }

    let subject = PassthroughSubject<SyncState, Never>()
    let base = MockGeneratorProtocol()
    let live = MockLiveGeneratorProtocol()
    let incremental = MockIncrementalGeneratorProtocol()

    init() {
        base.start_MockMethod = {}
        base.stop_MockMethod = {}
        live.start_MockMethod = {}
        live.stop_MockMethod = {}
        incremental.start_MockMethod = {}
        incremental.stop_MockMethod = {}
    }

    // MARK: - Tests

    @Test("idle / initialSyncing stops all generators", arguments: [
        SyncState.idle, .initialSyncing(.pullLastEventID),
        .initialSyncing(.pullResources),
        .initialSyncing(.pushSupportedProtocols),
        .initialSyncing(.resolveOneOnOneConversations)
    ])
    func idleStopsAllGenerators(state: SyncState) async {
        // GIVEN
        let sut = GeneratorsDirectory(
            generators: [base, live, incremental],
            syncStatePublisher: subject.eraseToAnyPublisher()
        )
        sut.observeSyncState()

        async let incrementalStoped: Void = waitForCall { resume in
            incremental.stop_MockMethod = { resume() }
        }

        // WHEN
        subject.send(state)
        _ = await incrementalStoped

        // THEN
        #expect(base.stop_Invocations.count == 1)
        #expect(live.stop_Invocations.count == 1)
        #expect(incremental.stop_Invocations.count == 1)
    }

    @Test("incrementalSyncing(.createPushChannel) starts incremental generators (and not live ones)")
    func createPushChannelStartsIncrementalGenerators() async {
        // GIVEN
        let sut = GeneratorsDirectory(
            generators: [live, incremental],
            syncStatePublisher: subject.eraseToAnyPublisher()
        )

        sut.observeSyncState()

        async let incrementalStarted: Void = waitForCall { resume in
            incremental.start_MockMethod = { resume() }
        }

        // Ensure live does NOT start on this state
        live.start_MockMethod = {
            Issue.record("Live generator should not start during incrementalSyncing(.createPushChannel)")
        }

        // WHEN
        subject.send(.incrementalSyncing(.createPushChannel))
        _ = await incrementalStarted

        // THEN
        #expect(incremental.start_Invocations.count == 1)
        #expect(live.start_Invocations.isEmpty)
    }

    @Test("liveSyncing(.ongoing) starts live generators (and not incremental ones)")
    func liveOngoingStartsLiveGenerators() async {
        // GIVEN
        let sut = GeneratorsDirectory(
            generators: [live, incremental],
            syncStatePublisher: subject.eraseToAnyPublisher()
        )
        sut.observeSyncState()

        async let liveStarted: Void = waitForCall { resume in
            live.start_MockMethod = { resume() }
        }

        incremental.start_MockMethod = {
            Issue.record("Incremental generator should not start during liveSyncing(.ongoing)")
        }

        // WHEN
        subject.send(.liveSyncing(.ongoing))
        _ = await liveStarted

        // THEN
        #expect(live.start_Invocations.count == 1)
        #expect(incremental.start_Invocations.isEmpty)
    }

    @Test(
        "suspended / liveSyncing(.finished) stops all generators",
        arguments: [SyncState.suspended, .liveSyncing(.finished)]
    )
    func suspendedAndFinishedStopAllGenerators(state: SyncState) async {
        // GIVEN
        let sut = GeneratorsDirectory(
            generators: [base, live],
            syncStatePublisher: subject.eraseToAnyPublisher()
        )
        sut.observeSyncState()

        async let baseStopped: Void = waitForCall { resume in
            base.stop_MockMethod = { resume() }
        }

        async let liveStopped: Void = waitForCall { resume in
            live.stop_MockMethod = { resume() }
        }

        // WHEN
        subject.send(state)
        _ = await baseStopped
        _ = await liveStopped

        // THEN
        #expect(base.stop_Invocations.count == 1)
        #expect(live.stop_Invocations.count == 1)
    }
}
