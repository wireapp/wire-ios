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
import Foundation

@MainActor
protocol KMPViewModelObservation: AnyObject {
    func cancel()
}

@MainActor
protocol KMPViewModelSource: AnyObject {
    associatedtype State
    associatedtype Effect
    associatedtype Intent

    var currentState: State { get }

    func observeState(_ observer: @escaping @MainActor (State) -> Void) -> KMPViewModelObservation
    func observeEffect(_ observer: @escaping @MainActor (Effect) -> Void) -> KMPViewModelObservation
    func send(_ intent: Intent)
    func close()
}

@MainActor
final class KMPViewModelAdapter<State, Effect, Intent>: ObservableObject {

    @Published private(set) var state: State
    @Published private(set) var effect: Effect?

    private let sendIntent: (Intent) -> Void
    private let closeSource: () -> Void
    private var observations = [KMPViewModelObservation]()
    private var isClosed = false

    init<Source: KMPViewModelSource>(
        source: Source
    ) where Source.State == State, Source.Effect == Effect, Source.Intent == Intent {
        self.state = source.currentState
        self.sendIntent = { source.send($0) }
        self.closeSource = { source.close() }

        observations = [
            source.observeState { [weak self] state in
                self?.state = state
            },
            source.observeEffect { [weak self] effect in
                self?.effect = effect
            }
        ]
    }

    deinit {
        guard !isClosed else { return }

        observations.forEach { $0.cancel() }
        closeSource()
    }

    func send(_ intent: Intent) {
        guard !isClosed else { return }
        sendIntent(intent)
    }

    func consumeEffect() {
        effect = nil
    }

    func close() {
        guard !isClosed else { return }

        isClosed = true
        observations.forEach { $0.cancel() }
        observations.removeAll()
        closeSource()
    }
}
