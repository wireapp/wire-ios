//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

public import Foundation

/// A debouncer that triggers the action immediately on the first call (leading)
/// and once more after a delay if additional calls occur (trailing).
/// Useful for responding instantly but also handling final state after other input.
public final class LeadingTrailingDebouncer<ID: Hashable> {

    private struct DebounceState {
        var isCooldown = false
        var pendingCall: (() -> Void)?
    }

    private let cooldownTime: TimeInterval
    private let queue: DispatchQueue
    private var states: [AnyHashable: DebounceState] = [:]

    // Unique key for `nil` ID
    private let nilKey = UUID()

    public init(cooldownTime: TimeInterval, queue: DispatchQueue = .main) {
        self.cooldownTime = cooldownTime
        self.queue = queue
    }

    public func call(id: ID?, block: @escaping () -> Void) {

        let key: AnyHashable = id.map { AnyHashable($0) } ?? AnyHashable(nilKey)

        if states[key] == nil {
            states[key] = DebounceState()
        }

        var state = states[key]!

        if !state.isCooldown {
            // LEADING: run immediately
            block()
            state.isCooldown = true

            queue.asyncAfter(deadline: .now() + cooldownTime) { [weak self] in
                guard let self else { return }

                var updatedState = states[key] ?? DebounceState()
                updatedState.isCooldown = false

                if let trailing = updatedState.pendingCall {
                    trailing()
                    updatedState.pendingCall = nil
                    updatedState.isCooldown = true

                    queue.asyncAfter(deadline: .now() + cooldownTime) {
                        self.states[key]?.isCooldown = false
                        self.states[key]?.pendingCall = nil
                    }
                }

                states[key] = updatedState
            }
        } else {
            // Store for TRAILING
            state.pendingCall = block
        }

        states[key] = state
    }
}
