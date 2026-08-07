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

    private static let currentDateRefreshInterval: Duration = .seconds(20)

    private(set) var loadedOccurrences: [MeetingOccurrence] = []
    private(set) var hasMore: Bool = false
    var hasDeleteError = false

    package var loadedMeetings: [Meeting] {
        loadedOccurrences.map(\.meeting)
    }

    private(set) var currentDate: Date

    /// Conversation ids of the meetings the self user is currently attending (joined a call in).
    private(set) var attendingConversationIDs: Set<QualifiedID> = []

    /// The meeting awaiting delete confirmation, or `nil` if no confirmation is in progress.
    var meetingToDelete: Meeting?

    var isDeleteConfirmationPresented: Bool {
        get { meetingToDelete != nil }
        set { if !newValue { meetingToDelete = nil } }
    }

    private let formatter: MeetingsFormatter
    private let currentDateProvider: any CurrentDateProviding
    private let upcomingMeetingsUseCase: any FetchUpcomingMeetingsUseCaseProtocol
    private let observeMeetingChangesUseCase: any ObserveMeetingChangesUseCaseProtocol
    private let deleteMeetingUseCase: any DeleteMeetingUseCaseProtocol
    private let observeAttendedMeetingsUseCase: (any ObserveAttendedMeetingsUseCaseProtocol)?

    private var futureOffset: Int = 0
    private let initialPageSize: Int = 20
    private let pageSize: Int = 20
    private var isLoading: Bool = false

    private let grouper = MeetingsGrouper()

    package init(
        currentDateProvider: any CurrentDateProviding,
        formatter: MeetingsFormatter = MeetingsFormatter(),
        upcomingMeetingsUseCase: any FetchUpcomingMeetingsUseCaseProtocol,
        observeMeetingChangesUseCase: any ObserveMeetingChangesUseCaseProtocol,
        deleteMeetingUseCase: any DeleteMeetingUseCaseProtocol,
        observeAttendedMeetingsUseCase: (any ObserveAttendedMeetingsUseCaseProtocol)? = nil
    ) {
        self.currentDateProvider = currentDateProvider
        self.formatter = formatter
        self.upcomingMeetingsUseCase = upcomingMeetingsUseCase
        self.observeMeetingChangesUseCase = observeMeetingChangesUseCase
        self.deleteMeetingUseCase = deleteMeetingUseCase
        self.observeAttendedMeetingsUseCase = observeAttendedMeetingsUseCase
        self.currentDate = currentDateProvider.now
    }

    // MARK: - Public Interface

    var groupedUpcomingMeetings: GroupedMeetings {
        grouper.group(loadedOccurrences)
    }

    func loadInitialData() async {
        futureOffset = 0
        loadedOccurrences = []
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

    func observeAttendedMeetings() async {
        guard let observeAttendedMeetingsUseCase else { return }
        for await ids in observeAttendedMeetingsUseCase.invoke() {
            attendingConversationIDs = ids
        }
    }

    /// Periodically refreshes the observable current date so time-based meeting state
    /// updates while the meetings list remains on screen.
    func observeCurrentDate() async {
        while !Task.isCancelled {
            refreshCurrentDate()

            do {
                try await Task.sleep(for: Self.currentDateRefreshInterval)
            } catch {
                return
            }
        }
    }

    func refreshCurrentDate() {
        currentDate = currentDateProvider.now
    }

    /// Whether the self user is currently attending (joined the call of) the given meeting.
    func isAttending(_ meeting: Meeting) -> Bool {
        attendingConversationIDs.contains(meeting.conversationID)
    }

    func isAttending(_ occurrence: MeetingOccurrence) -> Bool {
        attendingConversationIDs.contains(occurrence.conversationID) && isHappeningNow(occurrence)
    }

    /// Whether the meeting's scheduled time range contains the current time.
    func isHappeningNow(_ meeting: Meeting) -> Bool {
        meeting.start <= currentDate && currentDate < meeting.end
    }

    /// Whether the occurrence's scheduled time range contains the current time.
    func isHappeningNow(_ occurrence: MeetingOccurrence) -> Bool {
        occurrence.start <= currentDate && currentDate < occurrence.end
    }

    func formatDay(_ date: Date) -> String {
        formatter.dayHeader(for: date, now: currentDate)
    }

    func formatTimeRange(for meeting: Meeting) -> String {
        formatter.timeRange(from: meeting.start, to: meeting.end)
    }

    func formatTime(for occurrence: MeetingOccurrence) -> String {
        if isHappeningNow(occurrence) {
            formatter.startedAt(occurrence.start)
        } else {
            formatter.timeRange(from: occurrence.start, to: occurrence.end)
        }
    }

    /// Deletes the meeting awaiting confirmation. Synchronous on purpose: it must capture
    /// `meetingToDelete` before the alert dismissal clears it via `isDeleteConfirmationPresented`.
    func confirmDelete() {
        guard let meeting = meetingToDelete else { return }
        meetingToDelete = nil
        Task {
            await deleteMeeting(meeting)
        }
    }

    func deleteMeeting(_ meeting: Meeting) async {
        do {
            try await deleteMeetingUseCase.invoke(meetingID: meeting.id)
            loadedOccurrences.removeAll { $0.meeting.id == meeting.id }
        } catch {
            hasDeleteError = true
            WireLogger.meetings.error("failed to delete meeting: \(String(reflecting: error))")
        }
    }

    // MARK: - Private Methods

    /// Re-fetches everything that is currently loaded in a single page, because a
    /// change can insert or remove meetings anywhere in the loaded range.
    private func reloadLoadedMeetings() async {
        guard !isLoading else { return }
        let reloadSize = max(loadedOccurrences.count, initialPageSize)
        futureOffset = 0
        await load(pageSize: reloadSize)
    }

    private func load(pageSize: Int) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await upcomingMeetingsUseCase.invoke(pageSize: pageSize, offset: futureOffset)
            if futureOffset == 0 {
                loadedOccurrences = result.occurrences
            } else {
                loadedOccurrences += result.occurrences
            }

            futureOffset = result.nextOffset
            hasMore = result.hasMore
        } catch {
            hasMore = false
            WireLogger.meetings.error("failed to fetch upcoming meetings: \(String(reflecting: error))")
        }
    }

}
