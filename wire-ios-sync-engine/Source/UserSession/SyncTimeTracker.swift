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

/// Keep tracks of each sync phase duration and the start time of a given phase.
///
/// Used to log time for each sync phase along with the time a slow / quick sync took to complete.
final class SyncTimeTracker {
    var phaseStartTime: Date
    private var phasesDurations: [TimeInterval]

    init(
        phasesDurations: [TimeInterval] = [TimeInterval](),
        phaseStartTime: Date = .now
    ) {
        self.phasesDurations = phasesDurations
        self.phaseStartTime = phaseStartTime
    }

    func addPhaseDuration(
        _ duration: TimeInterval
    ) {
        phasesDurations.append(duration)
    }

    func totalSyncDuration() -> TimeInterval {
        phasesDurations.reduce(0, +)
    }

    func resetStartTime() {
        phaseStartTime = .now
    }

    func reset() {
        phaseStartTime = .now
        phasesDurations = []
    }
}
