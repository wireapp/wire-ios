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

package actor FetchUpcomingMeetingsUseCase: FetchUpcomingMeetingsUseCaseProtocol {

    private static let maximumPageSize = 20
    private static let sourceMeetingFetchLimit = Int.max / 2

    private let repository: any MeetingRepositoryProtocol
    private let currentDateProvider: any CurrentDateProviding
    private let occurrencePaginator = MeetingOccurrencePaginator()
    private var sourceMeetingSnapshot: SourceMeetingSnapshot?

    package init(
        repository: any MeetingRepositoryProtocol,
        currentDateProvider: any CurrentDateProviding
    ) {
        self.repository = repository
        self.currentDateProvider = currentDateProvider
    }

    package func invoke(pageSize: Int, offset: Int) async throws -> PaginatedMeetings {
        let pageSize = min(max(pageSize, 0), Self.maximumPageSize)
        let offset = max(offset, 0)
        guard pageSize > 0 else {
            return PaginatedMeetings(occurrences: [], hasMore: false, nextOffset: offset)
        }

        let snapshot = try await sourceMeetingSnapshot(refresh: offset == 0)
        let occurrences = occurrencePaginator.occurrences(
            for: snapshot.meetings,
            startingAt: snapshot.startOfToday,
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

    private func sourceMeetingSnapshot(refresh: Bool) async throws -> SourceMeetingSnapshot {
        if !refresh, let sourceMeetingSnapshot {
            return sourceMeetingSnapshot
        }

        // Occurrence pagination works on expanded rows, not raw meeting rows. We refresh
        // and load all source meetings at the start of a paging session, then reuse that
        // snapshot for load-more requests so scrolling does not repeatedly hit the backend
        // and reload the full local meeting set.
        let calendar = Calendar.current
        let snapshot = SourceMeetingSnapshot(
            startOfToday: calendar.startOfDay(for: currentDateProvider.now),
            meetings: try await repository.fetchMeetings(
                in: Date.distantPast ..< Date.distantFuture,
                offset: 0,
                limit: Self.sourceMeetingFetchLimit
            )
        )
        sourceMeetingSnapshot = snapshot
        return snapshot
    }

}

private struct SourceMeetingSnapshot: Sendable {
    let startOfToday: Date
    let meetings: [Meeting]
}
