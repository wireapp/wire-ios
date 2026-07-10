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

package struct FetchUpcomingMeetingsUseCase: FetchUpcomingMeetingsUseCaseProtocol {

    private let repository: any MeetingRepositoryProtocol
    private let currentDateProvider: any CurrentDateProviding

    package init(
        repository: any MeetingRepositoryProtocol,
        currentDateProvider: any CurrentDateProviding
    ) {
        self.repository = repository
        self.currentDateProvider = currentDateProvider
    }

    package func invoke(pageSize: Int, offset: Int) async throws -> PaginatedMeetings {
        let now = currentDateProvider.now
        let meetings = try await repository.fetchMeetingsStarting(
            after: now,
            offset: offset,
            limit: pageSize + 1
        )

        let hasMore = meetings.count > pageSize
        let page = hasMore ? Array(meetings.prefix(pageSize)) : meetings

        return PaginatedMeetings(
            meetings: page,
            hasMore: hasMore,
            nextOffset: offset + page.count
        )
    }

}
