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

package import WireCallingDomain
package import WireFoundation

import Foundation

@Observable
@MainActor
package final class MeetingsViewModel {

    private typealias Strings = L10n.Localizable.WireMeetings.List

    private(set) var loadedMeetings: [Meeting] = []
    private(set) var hasMore: Bool = false

    private let formatter: MeetingsFormatter
    private let currentDateProvider: any CurrentDateProviding
    private let upcomingMeetingsUseCase: any FetchUpcomingMeetingsUseCaseProtocol

    private var futureOffset: Int = 0
    private let initialPageSize: Int = 10
    private let pageSize: Int = 5
    private var isLoading: Bool = false

    private let grouper = MeetingsGrouper()

    package init(
        currentDateProvider: any CurrentDateProviding,
        formatter: MeetingsFormatter = MeetingsFormatter(),
        upcomingMeetingsUseCase: any FetchUpcomingMeetingsUseCaseProtocol
    ) {
        self.currentDateProvider = currentDateProvider
        self.formatter = formatter
        self.upcomingMeetingsUseCase = upcomingMeetingsUseCase
    }

    // MARK: - Public Interface

    var groupedUpcomingMeetings: GroupedMeetings {
        grouper.group(loadedMeetings)
    }

    func loadInitialData() {
        futureOffset = 0
        loadedMeetings = []
        hasMore = false
        load(pageSize: initialPageSize)
    }

    func loadMoreIfNeeded() {
        guard hasMore, !isLoading else { return }
        load(pageSize: pageSize)
    }

    func formatDay(_ date: Date) -> String {
        formatter.dayHeader(for: date, now: currentDateProvider.now)
    }

    func formatTimeRange(for meeting: Meeting) -> String {
        formatter.timeRange(from: meeting.start, to: meeting.end)
    }

    // MARK: - Private Methods

    private func load(pageSize: Int) {
        isLoading = true
        let result = upcomingMeetingsUseCase.invoke(pageSize: pageSize, offset: futureOffset)

        if futureOffset == 0 {
            loadedMeetings = result.meetings
        } else {
            loadedMeetings += result.meetings
        }

        futureOffset = result.nextOffset
        hasMore = result.hasMore
        isLoading = false
    }

}
