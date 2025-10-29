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
package import WireCallingDomain
package import WireFoundation

package final class MeetingsViewModel: ObservableObject {

    private typealias Strings = L10n.Localizable.WireMeetings.List

    @Published var selectedTab: Tab = .next
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
    @Published private(set) var cachedOngoingMeetings: [Meeting] = []
    @Published private(set) var cachedPastMeetings: GroupedMeetings = []

    private let repository: any MeetingsRepositoryProtocol
    private let formatter: MeetingsFormatter
    private let currentDateProvider: any CurrentDateProviding
    private let pastMeetingsUseCase: any FetchPastMeetingsUseCaseProtocol
    private let upcomingMeetingsUseCase: any FetchUpcomingMeetingsUseCaseProtocol

    private var futureOffset: Int = 0
    private let pageSize: Int = 50
    private let calendar = Calendar.current

    package init(
        repository: any MeetingsRepositoryProtocol,
        currentDateProvider: any CurrentDateProviding,
        formatter: MeetingsFormatter = MeetingsFormatter(),
        pastMeetingsUseCase: any FetchPastMeetingsUseCaseProtocol,
        upcomingMeetingsUseCase: any FetchUpcomingMeetingsUseCaseProtocol
    ) {
        self.repository = repository
        self.currentDateProvider = currentDateProvider
        self.formatter = formatter
        self.pastMeetingsUseCase = pastMeetingsUseCase
        self.upcomingMeetingsUseCase = upcomingMeetingsUseCase
    }

    // MARK: - Public Interface

    var ongoingMeetings: [Meeting] {
        cachedOngoingMeetings
    }

    var groupedPastMeetings: GroupedMeetings {
        cachedPastMeetings
    }

    var groupedNextMeetings: GroupedMeetings {
        upcomingMeetings
    }

    func loadInitialData() {
        refreshOngoingMeetings()
        refreshPastMeetings()
        loadUpcomingMeetings()
    }

    func loadMoreUpcomingMeetings() {
        loadUpcomingMeetings()
    }

    func refreshOngoingMeetings() {
        cachedOngoingMeetings = repository.fetchOngoingMeetings(at: currentDateProvider.now)
    }

    func refreshPastMeetings() {
        cachedPastMeetings = pastMeetingsUseCase.invoke()
    }

    func formatDay(_ date: Date) -> String {
        formatter.dayHeader(for: date, now: currentDateProvider.now)
    }

    func formatTime(_ date: Date) -> String {
        formatter.timeHeader(for: date)
    }

    // MARK: - Private Methods

    private func loadUpcomingMeetings() {
        let isLimited = !showAll
        let result = upcomingMeetingsUseCase.invoke(
            limitToTwoDays: isLimited,
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
        var mergedDict: [Date: [MeetingTimeSlot]] = [:]

        for group in existing + new {
            var slots = mergedDict[group.day] ?? []
            for newSlot in group.timeSlots {
                if let index = slots.firstIndex(where: { $0.time == newSlot.time }) {
                    let mergedMeetings = slots[index].meetings + newSlot.meetings
                    slots[index] = (time: newSlot.time, meetings: mergedMeetings)
                } else {
                    slots.append(newSlot)
                }
            }
            mergedDict[group.day] = slots.sorted { $0.time < $1.time }
        }

        return mergedDict.sorted { $0.key < $1.key }.map { (day: $0.key, timeSlots: $0.value) }
    }

}

extension MeetingsViewModel {

    enum Tab: Int, CaseIterable {
        case next
        case past

        var title: String {
            switch self {
            case .next: Strings.Tabs.next
            case .past: Strings.Tabs.past
            }
        }
    }

}

private extension Sequence<MeetingTimeSlot> {
    var meetingCount: Int {
        reduce(0) { $0 + $1.meetings.count }
    }
}

private extension Sequence<(day: Date, timeSlots: [MeetingTimeSlot])> {
    var meetingCount: Int {
        reduce(0) { $0 + $1.timeSlots.meetingCount }
    }
}
