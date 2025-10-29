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

import Foundation
package import WireFoundation

package struct FetchPastMeetingsUseCase: FetchPastMeetingsUseCaseProtocol {

    private let repository: any MeetingsRepositoryProtocol
    private let currentDateProvider: any CurrentDateProviding
    private let grouper: MeetingsGrouper
    private let calendar = Calendar.current

    package init(
        repository: any MeetingsRepositoryProtocol,
        currentDateProvider: any CurrentDateProviding
    ) {
        self.repository = repository
        self.currentDateProvider = currentDateProvider
        self.grouper = MeetingsGrouper()
    }

    /// Fetches past meetings: ended from yesterday 00:00 up to now.
    package func invoke() -> GroupedMeetings {
        let now = currentDateProvider.now
        let todayStart = calendar.startOfDay(for: now)
        guard let yesterdayStart = calendar.date(byAdding: .day, value: -1, to: todayStart) else {
            return []
        }
        let dateInterval = DateInterval(start: yesterdayStart, end: now)

        let allPast = repository.fetchMeetingsEnding(before: now)
        let displayedPast = allPast.filter { dateInterval.contains($0.end) }

        return grouper.group(displayedPast, byHours: true, sort: .descending)
    }

}
