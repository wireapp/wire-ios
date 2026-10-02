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

/// Selects upcoming starts whose reminder is still ahead. Occurrences starting within the
/// reminder lead time get no reminder, so they are skipped rather than counted towards the limit.
public struct MeetingReminderOccurrenceCalculator {

    public init() {}

    public func starts(for meeting: Meeting, after now: Date, limit: Int) -> [Date] {
        guard limit > 0 else { return [] }

        let earliestStart = now.addingTimeInterval(MeetingReminder.leadTime)
        // Request one extra occurrence because the first may start exactly at `earliestStart`.
        let fetchLimit = limit == Int.max ? limit : limit + 1
        return Array(MeetingOccurrencePaginator().occurrences(
            for: [meeting],
            startingAt: earliestStart,
            offset: 0,
            limit: fetchLimit
        )
        .map(\.start)
        .filter { $0 > earliestStart }
        .prefix(limit))
    }

}
