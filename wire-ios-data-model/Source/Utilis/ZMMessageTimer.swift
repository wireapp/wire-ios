//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

extension ZMMessageTimer {
    /// Starts a new timer if there is no existing one
    /// - Parameters:
    ///   - message: message passed to the timer's fireMethod
    ///   - fireDate The date at which the timer should fire
    ///   - userInfo: Additional info that should be added to the timer
    /// - Returns: True if timer was started, false otherwise
    @discardableResult
    public func startTimerIfNeeded(for message: ZMMessage, fireDate: Date, userInfo: [String: Any]) -> Bool {
        guard !isTimerRunning(for: message) else {
            return false
        }

        startTimer(for: message, fireDate: fireDate, userInfo: userInfo)
        return true
    }
}
