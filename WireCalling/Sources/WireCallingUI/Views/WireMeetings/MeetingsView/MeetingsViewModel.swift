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
package import WireCallingDomain
package import WireFoundation

package final class MeetingsViewModel: ObservableObject {

    private typealias Strings = L10n.Localizable.WireMeetings.List

    @Published var showAll: Bool = false {
        didSet {
            if oldValue != showAll {
                futureOffset = 0
                upcomingMeetings = []
                loadUpcomingMeetings()
            }
        }
    }

    @Published private(set) var showMoreButton: Bool = false
    @Published private(set) var upcomingMeetings: GroupedMeetings = []

    private let repository: any MeetingsRepositoryProtocol
    private let formatter: MeetingsFormatter
    private let currentDateProvider: any CurrentDateProviding
    private let upcomingMeetingsUseCase: any FetchUpcomingMeetingsUseCaseProtocol

    private var futureOffset: Int = 0
    private let pageSize: Int = 50
    private let calendar = Calendar.current

    package init(
        repository: any MeetingsRepositoryProtocol,
        currentDateProvider: any CurrentDateProviding,
        formatter: MeetingsFormatter = MeetingsFormatter(),
        upcomingMeetingsUseCase: any FetchUpcomingMeetingsUseCaseProtocol
    ) {
        self.repository = repository
        self.currentDateProvider = currentDateProvider
        self.formatter = formatter
        self.upcomingMeetingsUseCase = upcomingMeetingsUseCase
    }

    // MARK: - Public Interface

    var groupedUpcomingMeetings: GroupedMeetings {
        upcomingMeetings
    }

    func loadInitialData() {
        loadUpcomingMeetings()
    }

    func loadMoreUpcomingMeetings() {
        loadUpcomingMeetings()
    }

    func formatDay(_ date: Date) -> String {
        formatter.dayHeader(for: date, now: currentDateProvider.now)
    }

    func formatTimeRange(for meeting: Meeting) -> String {
        formatter.timeRange(from: meeting.start, to: meeting.end)
    }

    // MARK: - Private Methods

    private func loadUpcomingMeetings() {
        let isLimited = !showAll
        let result = upcomingMeetingsUseCase.invoke(
            pageSize: pageSize,
            offset: futureOffset
        )

        if futureOffset == 0 {
            upcomingMeetings = result.groups
        } else {
            upcomingMeetings = mergeGroups(existing: upcomingMeetings, new: result.groups)
        }

        futureOffset = result.nextOffset

        if isLimited {
            showMoreButton = calendar.todayAndTomorrowRange(using: currentDateProvider)
                .map { repository.hasUpcomingMeetings(after: $0.end) } ?? false
        } else {
            showMoreButton = result.hasMore
        }
    }

    private func mergeGroups(existing: GroupedMeetings, new: GroupedMeetings) -> GroupedMeetings {
        var mergedDict: [Date: [Meeting]] = [:]

        for group in existing + new {
            mergedDict[group.day, default: []] += group.meetings
        }

        return mergedDict
            .sorted { $0.key < $1.key }
            .map { (day: $0.key, meetings: sortMeetings($0.value)) }
    }

    // TODO: maybe add helper
    private func sortMeetings(_ meetings: [Meeting]) -> [Meeting] {
        meetings.sorted {
            if $0.start != $1.start {
                $0.start < $1.start
            } else {
                $0.title < $1.title
            }
        }
    }

}
