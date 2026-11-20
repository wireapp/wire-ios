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

import Foundation

extension ZMOTRMessage {

    /// How long a message waits for the network before it fails and has to be retried manually.
    public static let maxPendingDuration: TimeInterval = 7 * 24 * 60 * 60

    /// Until when the message waits for the network. Until the message is sent, its server timestamp is the
    /// time it was created or last retried.
    public var pendingDeadline: Date? {
        serverTimestamp?.addingTimeInterval(Self.maxPendingDuration)
    }

    /// Whether the message waited for the network longer than `maxPendingDuration`.
    public var hasPassedPendingDeadline: Bool {
        pendingDeadline.map { $0 <= .now } ?? false
    }

    /// Starts a new period of waiting for the network, e.g. when the user retries a failed message.
    func restartPendingPeriod() {
        serverTimestamp = Date()
    }
}
