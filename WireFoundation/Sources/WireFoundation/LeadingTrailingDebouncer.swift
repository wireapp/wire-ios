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

public import Foundation

/// A debouncer that triggers the action immediately on the first call (leading)
/// and once more after a delay if additional calls occur (trailing).
/// Useful for responding instantly but also handling final state after other input.
public final class LeadingTrailingDebouncer: @unchecked Sendable {

    private struct DebounceState {
        var isCooldown = false
        var pendingCall: (() -> Void)?
    }

    private let cooldownTime: TimeInterval
    private let queue: DispatchQueue = .main
    private var states: [UUID: DebounceState] = [:]

    // Unique key for `nil` ID
    private let nilKey = UUID()

    public init(cooldownTime: TimeInterval) {
        self.cooldownTime = cooldownTime
    }

    public func call(id: UUID?, block: @escaping () -> Void) {
        precondition(Thread.isMainThread) // the `states` dictionary should be updated from one thread only

        let key = id ?? nilKey

        if states[key] == nil {
            states[key] = DebounceState()
        }

        var state = states[key]!

        if !state.isCooldown {
            // LEADING: run immediately
            block()
            state.isCooldown = true
            states[key] = state

            queue.asyncAfter(deadline: .now() + cooldownTime) { [weak self] in
                guard let self else { return }

                var updatedState = states[key] ?? DebounceState()

                // Execute trailing call if pending
                if let trailing = updatedState.pendingCall {
                    trailing()
                }

                // Reset state
                updatedState.isCooldown = false
                updatedState.pendingCall = nil
                states[key] = updatedState
            }
        } else {
            // Store for TRAILING
            state.pendingCall = block
            states[key] = state
        }
    }
}
