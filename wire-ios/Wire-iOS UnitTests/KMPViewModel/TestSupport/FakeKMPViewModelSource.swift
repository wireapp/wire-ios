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

import XCTest

@testable import Wire

@MainActor
final class FakeKMPViewModelSource<State, Effect, Intent>: KMPViewModelSource {

    private(set) var currentState: State
    private(set) var sentIntents = [Intent]()
    private(set) var closeCallsCount = 0
    private(set) var cancelledObservationsCount = 0

    private var nextObservationID = 0
    private var stateObservers = [Int: @MainActor (State) -> Void]()
    private var effectObservers = [Int: @MainActor (Effect) -> Void]()

    var activeStateObservationsCount: Int {
        stateObservers.count
    }

    var activeEffectObservationsCount: Int {
        effectObservers.count
    }

    var activeObservationsCount: Int {
        activeStateObservationsCount + activeEffectObservationsCount
    }

    init(initialState: State) {
        self.currentState = initialState
    }

    func observeState(_ observer: @escaping @MainActor (State) -> Void) -> KMPViewModelObservation {
        let id = makeObservationID()
        stateObservers[id] = observer

        return FakeKMPViewModelObservation { [weak self] in
            guard let self else { return }

            stateObservers[id] = nil
            cancelledObservationsCount += 1
        }
    }

    func observeEffect(_ observer: @escaping @MainActor (Effect) -> Void) -> KMPViewModelObservation {
        let id = makeObservationID()
        effectObservers[id] = observer

        return FakeKMPViewModelObservation { [weak self] in
            guard let self else { return }

            effectObservers[id] = nil
            cancelledObservationsCount += 1
        }
    }

    func send(_ intent: Intent) {
        sentIntents.append(intent)
    }

    func close() {
        closeCallsCount += 1
    }

    func publish(state: State) {
        currentState = state
        Array(stateObservers.values).forEach { $0(state) }
    }

    func publish(effect: Effect) {
        Array(effectObservers.values).forEach { $0(effect) }
    }

    func makeAdapter() -> KMPViewModelAdapter<State, Effect, Intent> {
        KMPViewModelAdapter(source: self)
    }

    func makeDescriptor() -> KMPViewModelDescriptor<State, Effect, Intent> {
        KMPViewModelDescriptor(source: { self })
    }

    func makeHost() -> KMPViewModelHost<State, Effect, Intent> {
        KMPViewModelHost(descriptor: makeDescriptor())
    }

    func assertObserving(
        states expectedStateObservationsCount: Int = 1,
        effects expectedEffectObservationsCount: Int = 1,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(activeStateObservationsCount, expectedStateObservationsCount, file: file, line: line)
        XCTAssertEqual(activeEffectObservationsCount, expectedEffectObservationsCount, file: file, line: line)
    }

    func assertSentIntents(
        _ expected: [Intent],
        file: StaticString = #filePath,
        line: UInt = #line
    ) where Intent: Equatable {
        XCTAssertEqual(sentIntents, expected, file: file, line: line)
    }

    func assertClosed(
        times expectedCloseCallsCount: Int = 1,
        cancelledObservations expectedCancelledObservationsCount: Int = 2,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(closeCallsCount, expectedCloseCallsCount, file: file, line: line)
        XCTAssertEqual(cancelledObservationsCount, expectedCancelledObservationsCount, file: file, line: line)
        XCTAssertEqual(activeObservationsCount, 0, file: file, line: line)
    }

    func assertNotClosed(
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(closeCallsCount, 0, file: file, line: line)
        XCTAssertEqual(cancelledObservationsCount, 0, file: file, line: line)
    }

    private func makeObservationID() -> Int {
        defer { nextObservationID += 1 }
        return nextObservationID
    }
}
