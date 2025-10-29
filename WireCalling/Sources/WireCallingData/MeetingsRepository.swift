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

package import Foundation
package import WireCallingDomain

package final class MeetingsRepository: MeetingsRepositoryProtocol {

    private let meetingsSource: @Sendable () -> [Meeting]

    package init(meetings: @Sendable @escaping () -> [Meeting]) {
        self.meetingsSource = meetings
    }

    package func fetchOngoingMeetings(at date: Date) -> [Meeting] {
        meetingsSource().filter { $0.start <= date && $0.end > date }
    }

    package func fetchMeetingsEnding(before date: Date) -> [Meeting] {
        meetingsSource().filter { $0.end <= date }
    }

    package func fetchMeetingsStarting(after date: Date, offset: Int, limit: Int) -> [Meeting] {
        let allFuture = meetingsSource().filter { $0.start > date }
        let start = min(offset, allFuture.count)
        let end = min(offset + limit, allFuture.count)
        return Array(allFuture[start ..< end])
    }

    package func hasUpcomingMeetings(after date: Date) -> Bool {
        meetingsSource().contains { $0.start > date }
    }

}

package extension MeetingsRepository {
    static func demo() -> MeetingsRepository {
        let cal = Calendar.current
        let now = Date()
        func day(_ offset: Int, hour: Int, min: Int = 0) -> Date {
            cal.date(
                bySettingHour: hour,
                minute: min,
                second: 0,
                of: cal.date(byAdding: .day, value: offset, to: cal.startOfDay(for: now))!
            )!
        }
        let meetings: [Meeting] = [
            // YESTERDAY
            Meeting(
                id: UUID(),
                title: "iOS Playtest - develop build",
                start: day(-1, hour: 8, min: 0),
                end: day(-1, hour: 8, min: 30)
            ),
            Meeting(
                id: UUID(),
                title: "Sprint Review (all teams)",
                start: day(-1, hour: 16, min: 0),
                end: day(-1, hour: 16, min: 30)
            ),

            // TODAY — several at 7:00 AM for time grouping
            Meeting(
                id: UUID(),
                title: "Candidate interview",
                start: day(0, hour: 16, min: 0),
                end: day(0, hour: 16, min: 45)
            ),
            Meeting(
                id: UUID(),
                title: "Standup",
                start: day(0, hour: 7, min: 0),
                end: day(0, hour: 7, min: 30)
            ),
            Meeting(
                id: UUID(),
                title: "iOS team update",
                start: day(0, hour: 7, min: 0),
                end: day(0, hour: 7, min: 20)
            ),

            Meeting(
                id: UUID(),
                title: "Design review",
                start: day(0, hour: 12),
                end: day(0, hour: 13)
            ),

            // TOMORROW — again two meetings at 7:00 AM to group
            Meeting(
                id: UUID(),
                title: "Sprint planning",
                start: day(1, hour: 7),
                end: day(1, hour: 8)
            ),
            Meeting(
                id: UUID(),
                title: "Daily sync",
                start: day(1, hour: 7),
                end: day(1, hour: 7, min: 20)
            ),
            Meeting(
                id: UUID(),
                title: "Architecture Forum",
                start: day(1, hour: 13),
                end: day(1, hour: 14)
            ),

            // AFTER TOMORROW — ensures "Show All" appears in the Next tab
            Meeting(
                id: UUID(),
                title: "All hands",
                start: day(3, hour: 11),
                end: day(3, hour: 12)
            )
        ]

        return MeetingsRepository(meetings: { meetings })
    }
}
