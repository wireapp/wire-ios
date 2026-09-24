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
package import Foundation
package import WireFoundation

#if canImport(UIKit)
import UIKit
#endif
import WireLogging

@Observable
@MainActor
package final class MeetingsViewModel {

    private typealias Strings = L10n.Localizable.WireMeetings.List

    private(set) var loadedOccurrences: [MeetingOccurrence] = []
    private(set) var hasMore: Bool = false
    private(set) var isLoading = false
    private(set) var hasLoadError = false
    private(set) var isDeleting = false
    var hasDeleteError = false
    private var failedMeetingToDelete: Meeting?

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

    private var isDeletingForSelf: Bool {
        meetingToDelete.map { !isOrganizer($0) } ?? false
    }

    var deleteConfirmationTitle: String {
        if isDeletingForSelf {
            Strings.DeleteForMe.Alert.title
        } else if meetingToDelete?.recurrence != nil {
            Strings.DeleteRecurring.Alert.title
        } else {
            Strings.Delete.Alert.title
        }
    }

    var deleteConfirmationMessage: String {
        if isDeletingForSelf {
            Strings.DeleteForMe.Alert.subtitle
        } else if meetingToDelete?.recurrence != nil {
            Strings.DeleteRecurring.Alert.subtitle
        } else {
            Strings.Delete.Alert.subtitle
        }
    }

    var deleteErrorTitle: String {
        let strings = L10n.Localizable.Meetings.DeleteModal.Error.self
        return failedMeetingToDelete.map { !isOrganizer($0) } == true
            ? strings.leaveConversationFailedTitle : strings.deleteFailedTitle
    }

    var deleteErrorMessage: String {
        let strings = L10n.Localizable.Meetings.DeleteModal.Error.self
        return failedMeetingToDelete.map { !isOrganizer($0) } == true
            ? strings.leaveConversationFailed : strings.deleteFailed
    }

    private let formatter: MeetingsFormatter
    private let currentDateProvider: any CurrentDateProviding
    private let upcomingMeetingsUseCase: any FetchUpcomingMeetingsUseCaseProtocol
    private let observeMeetingChangesUseCase: any ObserveMeetingChangesUseCaseProtocol
    private let deleteMeetingUseCase: any DeleteMeetingUseCaseProtocol
    private let selfUserID: UUID
    private let observeAttendedMeetingsUseCase: (any ObserveAttendedMeetingsUseCaseProtocol)?

    private var futureOffset: Int = 0
    private let initialPageSize: Int = 20
    private let pageSize: Int = 20

    private let grouper = MeetingsGrouper()

    package init(
        currentDateProvider: any CurrentDateProviding,
        formatter: MeetingsFormatter = MeetingsFormatter(),
        upcomingMeetingsUseCase: any FetchUpcomingMeetingsUseCaseProtocol,
        observeMeetingChangesUseCase: any ObserveMeetingChangesUseCaseProtocol,
        deleteMeetingUseCase: any DeleteMeetingUseCaseProtocol,
        selfUserID: UUID,
        observeAttendedMeetingsUseCase: (any ObserveAttendedMeetingsUseCaseProtocol)? = nil
    ) {
        self.currentDateProvider = currentDateProvider
        self.formatter = formatter
        self.upcomingMeetingsUseCase = upcomingMeetingsUseCase
        self.observeMeetingChangesUseCase = observeMeetingChangesUseCase
        self.deleteMeetingUseCase = deleteMeetingUseCase
        self.selfUserID = selfUserID
        self.observeAttendedMeetingsUseCase = observeAttendedMeetingsUseCase
        self.currentDate = currentDateProvider.now
    }

    // MARK: - Public Interface

    var groupedUpcomingMeetings: GroupedMeetings {
        grouper.group(loadedOccurrences)
    }

    func loadInitialData() async {
        guard !isLoading else { return }
        futureOffset = 0
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
                try await Task.sleep(for: durationUntilNextMinute())
            } catch {
                return
            }
        }
    }

    func observeSystemDateTimeChanges() async {
        await observeSystemDateTimeChanges(Self.systemDateTimeChanges())
    }

    func observeSystemDateTimeChanges(_ changes: AsyncStream<Void>) async {
        for await _ in changes {
            refreshSystemDateTimeState()
        }
    }

    func refreshCurrentDate() {
        currentDate = currentDateProvider.now
    }

    func refreshSystemDateTimeState() {
        formatter.refresh()
        grouper.refresh()
        refreshCurrentDate()
    }

    /// Meeting start times are always minute-aligned, so the refresh is scheduled on the
    /// minute boundary rather than a fixed interval from when the screen appeared.
    func durationUntilNextMinute() -> Duration {
        let secondsIntoMinute = currentDateProvider.now.timeIntervalSince1970
            .truncatingRemainder(dividingBy: 60)
        return .seconds(60 - secondsIntoMinute)
    }

    /// Whether the self user is currently attending (joined the call of) the given meeting.
    func isAttending(_ meeting: Meeting) -> Bool {
        attendingConversationIDs.contains(meeting.conversationID)
    }

    func isAttending(_ occurrence: MeetingOccurrence) -> Bool {
        attendingConversationIDs.contains(occurrence.conversationID) && isHappeningNow(occurrence)
    }

    func isOrganizer(_ meeting: Meeting) -> Bool {
        meeting.creatorID.id == selfUserID
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
        formatter.timeRange(from: occurrence.start, to: occurrence.end)
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
        guard !isDeleting else { return }
        isDeleting = true
        hasDeleteError = false
        failedMeetingToDelete = nil
        defer { isDeleting = false }

        do {
            try await deleteMeetingUseCase.invoke(meeting: meeting)
            loadedOccurrences.removeAll { $0.meeting.id == meeting.id }
        } catch {
            failedMeetingToDelete = meeting
            hasDeleteError = true
            WireLogger.meetings.error("failed to delete meeting: \(String(reflecting: error))")
        }
    }

    func retryDelete() async {
        guard let meeting = failedMeetingToDelete else { return }
        await deleteMeeting(meeting)
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
        hasLoadError = false
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
            hasLoadError = true
            WireLogger.meetings.error("failed to fetch upcoming meetings: \(String(reflecting: error))")
        }
    }

}

private extension MeetingsViewModel {

    static var systemDateTimeChangeNotificationNames: [Notification.Name] {
        var names: [Notification.Name] = [
            .NSCalendarDayChanged,
            .NSSystemClockDidChange,
            .NSSystemTimeZoneDidChange,
            NSLocale.currentLocaleDidChangeNotification
        ]

        #if canImport(UIKit)
        names.append(contentsOf: [
            UIApplication.didBecomeActiveNotification,
            UIApplication.significantTimeChangeNotification
        ])
        #endif

        return names
    }

    static func systemDateTimeChanges(
        notificationCenter: NotificationCenter = .default
    ) -> AsyncStream<Void> {
        AsyncStream { continuation in
            let observer = DateTimeChangeNotificationObserver(
                notificationCenter: notificationCenter,
                names: systemDateTimeChangeNotificationNames,
                continuation: continuation
            )

            continuation.onTermination = { _ in
                observer.invalidate()
            }
        }
    }

}

private final class DateTimeChangeNotificationObserver: @unchecked Sendable {

    private let notificationCenter: NotificationCenter
    private let lock = NSLock()
    private var observers: [any NSObjectProtocol] = []

    init(
        notificationCenter: NotificationCenter,
        names: [Notification.Name],
        continuation: AsyncStream<Void>.Continuation
    ) {
        self.notificationCenter = notificationCenter
        self.observers = names.map { name in
            notificationCenter.addObserver(
                forName: name,
                object: nil,
                queue: .main
            ) { _ in
                continuation.yield(())
            }
        }
    }

    func invalidate() {
        lock.lock()
        let observers = observers
        self.observers.removeAll()
        lock.unlock()

        observers.forEach(notificationCenter.removeObserver)
    }

}
