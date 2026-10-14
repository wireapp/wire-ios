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
import WireDriveUploadsLiveActivity

/// Decides which states are worth sending to the activity.
///
/// The tracker reports progress about a hundred times per file, which is far more than ActivityKit
/// accepts. Anything that changes what the text says goes through at once, while progress alone is
/// limited to one update per interval.
struct WireDriveUploadsActivityThrottle {

    static let defaultMinimumProgressInterval: TimeInterval = 1

    private let minimumProgressInterval: TimeInterval
    private var lastSent: WireDriveUploadsActivityState?
    private var lastSentDate: Date?

    init(minimumProgressInterval: TimeInterval = Self.defaultMinimumProgressInterval) {
        self.minimumProgressInterval = minimumProgressInterval
    }

    /// Whether `state` should be sent now. Recording that it was sent is part of the decision.
    mutating func shouldSend(_ state: WireDriveUploadsActivityState, at date: Date) -> Bool {
        guard let lastSent, let lastSentDate else {
            record(state, at: date)
            return true
        }

        guard state != lastSent else { return false }

        var withoutProgress = state
        withoutProgress.progress = lastSent.progress

        if withoutProgress != lastSent || state.isFinished {
            record(state, at: date)
            return true
        }

        guard date.timeIntervalSince(lastSentDate) >= minimumProgressInterval else { return false }

        record(state, at: date)
        return true
    }

    mutating func reset() {
        lastSent = nil
        lastSentDate = nil
    }

    private mutating func record(_ state: WireDriveUploadsActivityState, at date: Date) {
        lastSent = state
        lastSentDate = date
    }
}
