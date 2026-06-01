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
package import WireFoundation

package struct FetchUpcomingMeetingsUseCase: FetchUpcomingMeetingsUseCaseProtocol {

    private let repository: any MeetingsRepositoryProtocol
    private let currentDateProvider: any CurrentDateProviding
    private let grouper: MeetingsGrouper
    private let calendar = Calendar.current

    package init(
        repository: any MeetingsRepositoryProtocol,
        currentDateProvider: any CurrentDateProviding,
        grouper: MeetingsGrouper = MeetingsGrouper()
    ) {
        self.repository = repository
        self.currentDateProvider = currentDateProvider
        self.grouper = grouper
    }

    package func invoke(pageSize: Int, offset: Int) -> PaginatedGroupedMeetings {
        let now = currentDateProvider.now
        let meetings = repository.fetchMeetingsStarting(
            after: now,
            offset: offset,
            limit: pageSize
        )

        let hasMore = meetings.count > pageSize
        let paginatedMeetings = hasMore ? Array(meetings.prefix(pageSize)) : meetings
        let groups = grouper.group(paginatedMeetings, sort: .ascending)

        return PaginatedGroupedMeetings(
            groups: groups,
            hasMore: hasMore,
            nextOffset: offset + pageSize
        )
    }

}
