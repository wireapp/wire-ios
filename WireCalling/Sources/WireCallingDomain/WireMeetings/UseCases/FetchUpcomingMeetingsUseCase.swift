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

package import WireFoundation

import Foundation

package struct FetchUpcomingMeetingsUseCase: FetchUpcomingMeetingsUseCaseProtocol {

    private static let maximumPageSize = 20
    private static let sourceMeetingFetchLimit = Int.max / 2

    private let repository: any MeetingRepositoryProtocol
    private let currentDateProvider: any CurrentDateProviding
    private let occurrencePaginator = MeetingOccurrencePaginator()

    package init(
        repository: any MeetingRepositoryProtocol,
        currentDateProvider: any CurrentDateProviding
    ) {
        self.repository = repository
        self.currentDateProvider = currentDateProvider
    }

    package func invoke(pageSize: Int, offset: Int) async throws -> PaginatedMeetings {
        let pageSize = min(max(pageSize, 0), Self.maximumPageSize)
        guard pageSize > 0 else {
            return PaginatedMeetings(occurrences: [], hasMore: false, nextOffset: offset)
        }

        // The list starts at the beginning of today, so meetings earlier
        // today remain visible and recurring meetings can produce future
        // occurrence rows even when their source meeting started in the past.
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: currentDateProvider.now)
        let sourceMeetings = try await repository.fetchMeetings(
            in: Date.distantPast ..< Date.distantFuture,
            offset: 0,
            limit: Self.sourceMeetingFetchLimit
        )
        let occurrences = occurrencePaginator.occurrences(
            for: sourceMeetings,
            startingAt: startOfToday,
            offset: offset,
            limit: pageSize + 1
        )

        let hasMore = occurrences.count > pageSize
        let page = hasMore ? Array(occurrences.prefix(pageSize)) : occurrences

        return PaginatedMeetings(
            occurrences: page,
            hasMore: hasMore,
            nextOffset: offset + page.count
        )
    }

}
