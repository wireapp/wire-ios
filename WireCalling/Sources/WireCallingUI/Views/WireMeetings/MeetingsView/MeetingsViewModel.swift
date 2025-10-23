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
package import WireFoundation

package final class MeetingsViewModel: ObservableObject {

    private typealias Strings = L10n.Localizable.WireMeetings.List

    @Published var selectedTab: Tab = .next
    @Published var showAll: Bool = false {
        didSet {
            if oldValue != showAll {
                futureOffset = 0
                futureMeetings = []
                loadFutureMeetings()
            }
        }
    }
    @Published var futureMeetings: GroupedMeetings = []
    @Published var showMoreButton: Bool = false

    private let repository: any MeetingsRepositoryProtocol
    private let formatter: MeetingsFormatter
    private let currentDateProvider: any CurrentDateProviding
    private let pastMeetingsUseCase: any FetchPastMeetingsUseCaseProtocol
    private let ongoingMeetingsUseCase: any FetchOngoingMeetingsUseCaseProtocol
    private let upcomingMeetingsUseCase: any FetchUpcomingMeetingsUseCaseProtocol

    @Published var hasMoreFutureMeetings: Bool = false
    private var futureOffset: Int = 0
    private let pageSize: Int = 50
    private let offset: Int = 0


    package init(
        repository: any MeetingsRepositoryProtocol,
        currentDateProvider: any CurrentDateProviding,
        formatter: MeetingsFormatter = MeetingsFormatter(),
        pastMeetingsUseCase: any FetchPastMeetingsUseCaseProtocol,
        ongoingMeetingsUseCase: any FetchOngoingMeetingsUseCaseProtocol,
        upcomingMeetingsUseCase: any FetchUpcomingMeetingsUseCaseProtocol
    ) {
        self.repository = repository
        self.currentDateProvider = currentDateProvider
        self.formatter = formatter
        self.pastMeetingsUseCase = pastMeetingsUseCase
        self.ongoingMeetingsUseCase = ongoingMeetingsUseCase
        self.upcomingMeetingsUseCase = upcomingMeetingsUseCase

        loadFutureMeetings()
    }

    package var ongoingMeetings: [Meeting] {
        ongoingMeetingsUseCase.invoke()
    }

    package var groupedPastMeetings: GroupedMeetings {
        pastMeetingsUseCase.invoke()
    }

    package var groupedNext: GroupedMeetings {
        futureMeetings
    }

    package func formatDay(_ date: Date) -> String {
        formatter.dayHeader(for: date, now: currentDateProvider.now)
    }

    func formatTime(_ date: Date) -> String {
        formatter.timeHeader(for: date)
    }

    func meetNowTapped() {}
    func scheduleMeetingTapped() {}

    private func loadFutureMeetings() {
        let isLimited = !showAll
        let currentPageSize = isLimited ? Int.max : pageSize
        let result = upcomingMeetingsUseCase.invoke(
            limitToTwoDays: isLimited,
            pageSize: currentPageSize,
            offset: futureOffset
        )

        if futureOffset == 0 {
            futureMeetings = result.groups
        } else {
            futureMeetings = mergeGroups(existing: futureMeetings, new: result.groups)
        }

        hasMoreFutureMeetings = result.hasMore
        futureOffset = result.nextOffset

        if isLimited {
            let total = repository.totalCountFutureMeetings(after: currentDateProvider.now)
            showMoreButton = total > futureMeetings.meetingCount
        } else {
            showMoreButton = false
        }
    }

    private func mergeGroups(existing: GroupedMeetings, new: GroupedMeetings) -> GroupedMeetings {
        var mergedDict: [Date: [MeetingTimeSlot]] = [:]

        for group in existing + new {
            var slots = mergedDict[group.day] ?? []
            for newSlot in group.timeSlots {
                if let index = slots.firstIndex(where: { $0.time == newSlot.time }) {
                    slots[index].meetings.append(contentsOf: newSlot.meetings)
                } else {
                    slots.append(newSlot)
                }
            }
            mergedDict[group.day] = slots.sorted { $0.time < $1.time }
        }

        return mergedDict.sorted { $0.key < $1.key }.map { (day: $0.key, timeSlots: $0.value) }
    }

}

package extension MeetingsViewModel {

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

private extension Sequence where Element == MeetingTimeSlot {
    var meetingCount: Int {
        reduce(0) { $0 + $1.meetings.count }
    }
}

private extension Sequence where Element == (day: Date, timeSlots: [MeetingTimeSlot]) {
    var meetingCount: Int {
        reduce(0) { $0 + $1.timeSlots.meetingCount }
    }
}
