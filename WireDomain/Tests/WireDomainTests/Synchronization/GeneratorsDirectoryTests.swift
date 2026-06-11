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

        let (baseStream, baseCont) = AsyncStream<Void>.makeStream()
        let (liveStream, liveCont) = AsyncStream<Void>.makeStream()
        let (incrementalStream, incrementalCont) = AsyncStream<Void>.makeStream()
        base.stop_MockMethod = { baseCont.yield() }
        live.stop_MockMethod = { liveCont.yield() }
        incremental.stop_MockMethod = { incrementalCont.yield() }

        // WHEN
        subject.send(state)
        async let baseStopped = baseStream.waitForCall()
        async let liveStopped = liveStream.waitForCall()
        async let incrementalStopped = incrementalStream.waitForCall()
        #expect(await baseStopped)
        #expect(await liveStopped)
        #expect(await incrementalStopped)

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

        let (incrementalStream, incrementalCont) = AsyncStream<Void>.makeStream()
        incremental.start_MockMethod = { incrementalCont.yield() }
        live.start_MockMethod = {
            Issue.record("Live generator should not start during incrementalSyncing(.createPushChannel)")
        }

        // WHEN
        subject.send(.incrementalSyncing(.createPushChannel))
        #expect(await incrementalStream.waitForCall())

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

        let (liveStream, liveCont) = AsyncStream<Void>.makeStream()
        live.start_MockMethod = { liveCont.yield() }
        incremental.start_MockMethod = {
            Issue.record("Incremental generator should not start during liveSyncing(.ongoing)")
        }

        // WHEN
        subject.send(.liveSyncing(.ongoing))
        #expect(await liveStream.waitForCall())

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

        let (baseStream, baseCont) = AsyncStream<Void>.makeStream()
        let (liveStream, liveCont) = AsyncStream<Void>.makeStream()
        base.stop_MockMethod = { baseCont.yield() }
        live.stop_MockMethod = { liveCont.yield() }

        // WHEN
        subject.send(state)
        async let baseStopped = baseStream.waitForCall()
        async let liveStopped = liveStream.waitForCall()
        #expect(await baseStopped)
        #expect(await liveStopped)

        // THEN
        #expect(base.stop_Invocations.count == 1)
        #expect(live.stop_Invocations.count == 1)
    }
}

// MARK: - Helpers

private extension AsyncStream where Element == Void {

    /// Waits for the stream to yield its first element within `timeout`.
    /// Returns `false` if the timeout elapses first, so callers can use `#expect`
    /// to get a failure attributed to the right source location.
    func waitForCall(timeout: Duration = .seconds(2)) async -> Bool {
        await withTaskGroup(of: Bool.self) { group in
            group.addTask {
                var iteration = self.makeAsyncIterator()
                return await iteration.next() != nil
            }
            group.addTask {
                try? await Task.sleep(for: timeout)
                return false
            }
            defer { group.cancelAll() }
            return await group.next() ?? false
        }
    }
}
