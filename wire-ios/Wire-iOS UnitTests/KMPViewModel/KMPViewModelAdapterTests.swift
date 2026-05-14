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
import XCTest

@testable import Wire

@MainActor
final class KMPViewModelAdapterTests: XCTestCase {

    private var cancellables = Set<AnyCancellable>()

    override func tearDown() {
        cancellables.removeAll()
    }

    func testAdapterPublishesStateAndEffectsAndForwardsIntent() {
        // GIVEN
        let source = FakeKMPViewModelSource(initialState: .idle)
        let sut = KMPViewModelAdapter<TestState, TestEffect, TestIntent>(source: source)
        var states = [TestState]()
        var effects = [TestEffect]()

        sut.$state
            .sink { states.append($0) }
            .store(in: &cancellables)

        sut.$effect
            .compactMap { $0 }
            .sink { effects.append($0) }
            .store(in: &cancellables)

        // WHEN
        source.publish(state: .loaded("conversation-list"))
        source.publish(effect: .showToast("synced"))
        sut.send(.refresh)

        // THEN
        XCTAssertEqual(states, [.idle, .loaded("conversation-list")])
        XCTAssertEqual(effects, [.showToast("synced")])
        XCTAssertEqual(source.sentIntents, [.refresh])
    }

    func testCloseDisconnectsObservationsAndClosesSource() {
        // GIVEN
        let source = FakeKMPViewModelSource(initialState: .idle)
        let sut = KMPViewModelAdapter<TestState, TestEffect, TestIntent>(source: source)
        var states = [TestState]()
        var effects = [TestEffect]()

        sut.$state
            .sink { states.append($0) }
            .store(in: &cancellables)

        sut.$effect
            .compactMap { $0 }
            .sink { effects.append($0) }
            .store(in: &cancellables)

        // WHEN
        sut.close()
        source.publish(state: .loaded("after-close"))
        source.publish(effect: .showToast("ignored"))
        sut.send(.refresh)
        sut.close()

        // THEN
        XCTAssertEqual(states, [.idle])
        XCTAssertTrue(effects.isEmpty)
        XCTAssertEqual(source.closeCallsCount, 1)
        XCTAssertEqual(source.cancelledObservationsCount, 2)
        XCTAssertTrue(source.sentIntents.isEmpty)
    }

    func testDeinitAfterCloseDoesNotCloseSourceTwice() {
        // GIVEN
        let source = FakeKMPViewModelSource(initialState: .idle)
        var sut: KMPViewModelAdapter<TestState, TestEffect, TestIntent>? = KMPViewModelAdapter(source: source)

        // WHEN
        sut?.close()
        sut = nil

        // THEN
        XCTAssertEqual(source.closeCallsCount, 1)
        XCTAssertEqual(source.cancelledObservationsCount, 2)
    }
}

// MARK: - Test Types

private enum TestState: Equatable {
    case idle
    case loaded(String)
}

private enum TestEffect: Equatable {
    case showToast(String)
}

private enum TestIntent: Equatable {
    case refresh
}

// MARK: - Fakes

@MainActor
private final class FakeKMPViewModelSource: KMPViewModelSource {

    private(set) var currentState: TestState
    private(set) var sentIntents = [TestIntent]()
    private(set) var closeCallsCount = 0
    private(set) var cancelledObservationsCount = 0

    private var nextObservationID = 0
    private var stateObservers = [Int: @MainActor (TestState) -> Void]()
    private var effectObservers = [Int: @MainActor (TestEffect) -> Void]()

    init(initialState: TestState) {
        self.currentState = initialState
    }

    func observeState(_ observer: @escaping @MainActor (TestState) -> Void) -> KMPViewModelObservation {
        let id = makeObservationID()
        stateObservers[id] = observer

        return FakeKMPViewModelObservation { [weak self] in
            guard let self else { return }

            stateObservers[id] = nil
            cancelledObservationsCount += 1
        }
    }

    func observeEffect(_ observer: @escaping @MainActor (TestEffect) -> Void) -> KMPViewModelObservation {
        let id = makeObservationID()
        effectObservers[id] = observer

        return FakeKMPViewModelObservation { [weak self] in
            guard let self else { return }

            effectObservers[id] = nil
            cancelledObservationsCount += 1
        }
    }

    func send(_ intent: TestIntent) {
        sentIntents.append(intent)
    }

    func close() {
        closeCallsCount += 1
    }

    func publish(state: TestState) {
        currentState = state
        stateObservers.values.forEach { $0(state) }
    }

    func publish(effect: TestEffect) {
        effectObservers.values.forEach { $0(effect) }
    }

    private func makeObservationID() -> Int {
        defer { nextObservationID += 1 }
        return nextObservationID
    }
}

@MainActor
private final class FakeKMPViewModelObservation: KMPViewModelObservation {

    private let onCancel: () -> Void
    private var isCancelled = false

    init(onCancel: @escaping () -> Void) {
        self.onCancel = onCancel
    }

    func cancel() {
        guard !isCancelled else { return }

        isCancelled = true
        onCancel()
    }
}
