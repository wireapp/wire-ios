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
import WireLogging

@Observable
@MainActor
package final class MeetingsViewModel {

    private typealias Strings = L10n.Localizable.WireMeetings.List

    private(set) var loadedMeetings: [Meeting] = []
    private(set) var hasMore: Bool = false

    private let formatter: MeetingsFormatter
    private let currentDateProvider: any CurrentDateProviding
    private let upcomingMeetingsUseCase: any FetchUpcomingMeetingsUseCaseProtocol
    private let observeMeetingChangesUseCase: any ObserveMeetingChangesUseCaseProtocol
    private let deleteMeetingUseCase: any DeleteMeetingUseCaseProtocol

    private var futureOffset: Int = 0
    private let initialPageSize: Int = 10
    private let pageSize: Int = 5
    private var isLoading: Bool = false

    private let grouper = MeetingsGrouper()

    package init(
        currentDateProvider: any CurrentDateProviding,
        formatter: MeetingsFormatter = MeetingsFormatter(),
        upcomingMeetingsUseCase: any FetchUpcomingMeetingsUseCaseProtocol,
        observeMeetingChangesUseCase: any ObserveMeetingChangesUseCaseProtocol
        upcomingMeetingsUseCase: any FetchUpcomingMeetingsUseCaseProtocol,
        deleteMeetingUseCase: any DeleteMeetingUseCaseProtocol
    ) {
        self.currentDateProvider = currentDateProvider
        self.formatter = formatter
        self.upcomingMeetingsUseCase = upcomingMeetingsUseCase
        self.observeMeetingChangesUseCase = observeMeetingChangesUseCase
        self.deleteMeetingUseCase = deleteMeetingUseCase
    }

    // MARK: - Public Interface

    var groupedUpcomingMeetings: GroupedMeetings {
        grouper.group(loadedMeetings)
    }

    func loadInitialData() async {
        futureOffset = 0
        loadedMeetings = []
        hasMore = false
        await load(pageSize: initialPageSize)
    }

    func loadMoreIfNeeded() async {
        guard hasMore, !isLoading else { return }
        await load(pageSize: pageSize)
    }

    /// Reloads the loaded meetings whenever they are changed outside of this screen,
    /// e.g. by background sync. Runs until the surrounding task is cancelled.
    func observeMeetingChanges() async {
        for await _ in observeMeetingChangesUseCase.invoke() {
            await reloadLoadedMeetings()
        }
    }

    func formatDay(_ date: Date) -> String {
        formatter.dayHeader(for: date, now: currentDateProvider.now)
    }

    func formatTimeRange(for meeting: Meeting) -> String {
        formatter.timeRange(from: meeting.start, to: meeting.end)
    }

    func deleteMeeting(_ meeting: Meeting) async throws {
        try await deleteMeetingUseCase.invoke(meetingID: meeting.id)
        loadedMeetings.removeAll { $0.id == meeting.id }
    }

    // MARK: - Private Methods

    /// Re-fetches everything that is currently loaded in a single page, because a
    /// change can insert or remove meetings anywhere in the loaded range.
    private func reloadLoadedMeetings() async {
        guard !isLoading else { return }
        let reloadSize = max(loadedMeetings.count, initialPageSize)
        futureOffset = 0
        await load(pageSize: reloadSize)
    }

    private func load(pageSize: Int) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await upcomingMeetingsUseCase.invoke(pageSize: pageSize, offset: futureOffset)
            if futureOffset == 0 {
                loadedMeetings = result.meetings
            } else {
                loadedMeetings += result.meetings
            }

            futureOffset = result.nextOffset
            hasMore = result.hasMore
        } catch {
            let errorType = Swift.type(of: error)
            WireLogger.ui.error("failed to fetch upcoming meetings: \(String(describing: errorType))")
        }
    }

}
