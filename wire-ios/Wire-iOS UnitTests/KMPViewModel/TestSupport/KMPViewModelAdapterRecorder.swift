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
final class KMPViewModelAdapterRecorder<State, Effect> {

    private var cancellables = Set<AnyCancellable>()

    private(set) var states = [State]()
    private(set) var effects = [Effect]()
    private(set) var rawEffects = [Effect?]()

    init<Intent>(
        adapter: KMPViewModelAdapter<State, Effect, Intent>,
        recordsNilEffects: Bool = false
    ) {
        adapter.$state
            .sink { [weak self] state in
                self?.states.append(state)
            }
            .store(in: &cancellables)

        adapter.$effect
            .sink { [weak self] effect in
                guard let self else { return }

                if recordsNilEffects {
                    rawEffects.append(effect)
                }

                if let effect {
                    effects.append(effect)
                }
            }
            .store(in: &cancellables)
    }

    func cancel() {
        cancellables.removeAll()
    }

    func assertStates(
        _ expected: [State],
        file: StaticString = #filePath,
        line: UInt = #line
    ) where State: Equatable {
        XCTAssertEqual(states, expected, file: file, line: line)
    }

    func assertEffects(
        _ expected: [Effect],
        file: StaticString = #filePath,
        line: UInt = #line
    ) where Effect: Equatable {
        XCTAssertEqual(effects, expected, file: file, line: line)
    }

    func assertRawEffects(
        _ expected: [Effect?],
        file: StaticString = #filePath,
        line: UInt = #line
    ) where Effect: Equatable {
        XCTAssertEqual(rawEffects, expected, file: file, line: line)
    }
}
