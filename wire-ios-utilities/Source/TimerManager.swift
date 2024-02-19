////
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

public final class TimerManager<Identifier: Hashable> {

    public enum TimerError: Error {
        case timerAlreadyExists
        case timerNotFound
    }

    private var timers: [Identifier: Timer] = [:]

    public init() {}

    public func startTimer(
        for identifier: Identifier,
        duration: TimeInterval,
        completion: @escaping () -> Void
    ) throws {
        guard timers[identifier] == nil else {
            throw TimerError.timerAlreadyExists
        }

        let timer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            self?.timerExpired(for: identifier, completion: completion)
        }

        timers[identifier] = timer
    }

    public func cancelTimer(for identifier: Identifier) throws {
        guard let timer = timers[identifier] else {
            throw TimerError.timerNotFound
        }

        timer.invalidate()
        timers.removeValue(forKey: identifier)
    }

    public func cancelAllTimers() {
        timers.forEach {
            $0.value.invalidate()
        }

        timers.removeAll()
    }

    private func timerExpired(
        for identifier: Identifier,
        completion: @escaping () -> Void
    ) {
        completion()
        timers.removeValue(forKey: identifier)
    }
}
