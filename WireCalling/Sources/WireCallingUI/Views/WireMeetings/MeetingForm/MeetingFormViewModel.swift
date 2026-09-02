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
package final class MeetingFormViewModel {

    /// Determines whether the form creates a meeting (starting immediately
    /// or scheduled for a future date and time) or edits an existing one.
    /// Drives the form layout (schedule fields are hidden in `.instant`),
    /// the navigation title, and the primary action button's label and
    /// behavior.
    package enum Mode: Hashable, Identifiable {

        /// Start the meeting immediately. The schedule section
        /// (start/end/repeat) is hidden; the action button reads "Start" and
        /// the screen is titled "Meet Now".
        case instant

        /// Schedule the meeting for a future date and time. The schedule
        /// section is visible; the action button reads "Schedule" and the
        /// screen is titled "Schedule a meeting".
        case scheduled

        /// Edit an existing meeting. The form is pre-filled with the
        /// meeting's data; the action button reads "Save" and the screen
        /// is titled "Edit meeting".
        case edit(Meeting)

        package var id: Self { self }

        var isEdit: Bool {
            if case .edit = self { true } else { false }
        }
    }

    let mode: Mode
    let searchMembersUseCase: any SearchMembersUseCaseProtocol
    private let createMeetingUseCase: any CreateMeetingUseCaseProtocol
    private let updateMeetingUseCase: any UpdateMeetingUseCaseProtocol
    private let currentDateProvider: any CurrentDateProviding
    private let onSuccess: (Meeting) -> Void

    private static let timePickerMinuteInterval = 15
    // Match the limits enforced by SimpleTextFieldValidator for conversation names.
    private static let maximumConversationNameLength = 64
    private static let maximumConversationNameByteLength = 256

    /// The smallest selectable interval between start and end time.
    private static let minimumDuration = TimeInterval(timePickerMinuteInterval) * TimeInterval.oneMinute

    var meetingTitle: String = ""

    /// Changing the start date normally preserves duration. If that would pass
    /// the same-day limit, the end time is clamped instead.
    var startDate: Date {
        didSet {
            let shiftedEndDate = endDate.addingTimeInterval(startDate.timeIntervalSince(oldValue))
            endDate = Self.adjustedEndDate(shiftedEndDate, forStartDate: startDate)
        }
    }

    /// The end date follows the start date's calendar day and can't go past 23:45.
    var endDate: Date {
        didSet {
            let adjustedEndDate = Self.adjustedEndDate(endDate, forStartDate: startDate)
            if adjustedEndDate != endDate {
                endDate = adjustedEndDate
            }
        }
    }

    /// Scheduled meetings start at the next available picker interval.
    /// When editing a meeting whose start lies in the past, its original day
    /// stays selectable unless it is recurring; recurring meetings are moved
    /// to their next editable occurrence so the backend receives a non-past start date.
    var startDateRange: PartialRangeFrom<Date> {
        var earliest = currentDateProvider.now
        if case .scheduled = mode {
            return Self.nextSelectableStartDate(after: earliest)...
        }
        if case let .edit(meeting) = mode, meeting.recurrence == nil {
            earliest = min(earliest, meeting.start)
        }
        return Calendar.current.startOfDay(for: earliest)...
    }

    /// Acceptance: the end picker must stay on the start date, with 23:45 as the latest available time.
    var endDateRange: ClosedRange<Date> {
        let latestEndDate = Self.latestEndDate(for: startDate)
        let earliestEndDate = min(startDate.addingTimeInterval(Self.minimumDuration), latestEndDate)
        return earliestEndDate ... latestEndDate
    }

    var repeatOption: MeetingRepeatOption = .never
    var availableRepeatOptions: [MeetingRepeatOption] {
        // Monthly and Yearly are only shown when editing meetings that already use them.
        MeetingRepeatOption.allCases.filter {
            ($0 != .monthly && $0 != .yearly) || $0 == repeatOption
        }
    }

    var selectedMembers: [MeetingMember] = []
    private(set) var isLoading = false

    /// Set when creating a meeting fails. The caught error itself is only
    /// logged; the view shows a generic alert.
    var hasError = false

    /// Set when the meeting was saved but its dedicated conversation could not be renamed.
    var hasConversationNameUpdateError = false
    private var meetingPendingConversationNameUpdate: Meeting?

    var selectedMembersSummary: String {
        selectedMembers
            .map(\.name)
            .joined(separator: ", ")
    }

    var isNextButtonEnabled: Bool {
        !meetingTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isMeetingTitleTooLong
    }

    var isMeetingTitleTooLong: Bool {
        meetingTitle.count > Self.maximumConversationNameLength ||
            meetingTitle.utf8.count > Self.maximumConversationNameByteLength
    }

    // MARK: - Public Interface

    package init(
        mode: Mode,
        searchMembersUseCase: any SearchMembersUseCaseProtocol,
        createMeetingUseCase: any CreateMeetingUseCaseProtocol,
        updateMeetingUseCase: any UpdateMeetingUseCaseProtocol,
        currentDateProvider: any CurrentDateProviding,
        onSuccess: @escaping (Meeting) -> Void = { _ in }
    ) {
        self.mode = mode
        self.searchMembersUseCase = searchMembersUseCase
        self.createMeetingUseCase = createMeetingUseCase
        self.updateMeetingUseCase = updateMeetingUseCase
        self.currentDateProvider = currentDateProvider
        self.onSuccess = onSuccess

        switch mode {
        case .instant, .scheduled:
            let startDate = Self.nextSelectableStartDate(after: currentDateProvider.now)
            self.startDate = startDate
            self.endDate = Self.adjustedEndDate(
                startDate.addingTimeInterval(TimeInterval.oneHour),
                forStartDate: startDate
            )
        case let .edit(meeting):
            let editableTimeRange = Self.editableTimeRange(for: meeting, now: currentDateProvider.now)
            self.startDate = editableTimeRange.start
            self.endDate = Self.adjustedEndDate(editableTimeRange.end, forStartDate: editableTimeRange.start)
            self.meetingTitle = meeting.title
            self.repeatOption = MeetingRepeatOption(recurrence: meeting.recurrence)
            // The participants come from the meeting's conversation; the
            // creator is implicit in the selection, matching the create flow.
            self.selectedMembers = (meeting.conversation?.participants ?? [])
                .filter { $0.qualifiedID != meeting.creatorID }
                .sorted { $0.name < $1.name }
        }
    }

    func clearTitle() {
        meetingTitle = ""
    }

    func makeMemberSelectionViewModel() -> MemberSelectionViewModel {
        MemberSelectionViewModel(
            source: searchMembersUseCase,
            initialSelection: selectedMembers,
            onSelect: { [weak self] in self?.selectedMembers = $0 }
        )
    }

    func submit() async {
        // TODO: [WPB-20274] reloadLoadedMeetings() sets futureOffset = 0 before calling load(pageSize:), but
        // load(pageSize:) catches errors internally and does not restore the previous offset on failure. If the fetch
        // throws, futureOffset stays at 0 while loadedMeetings still contains the previously loaded page(s), which can
        // corrupt subsequent pagination (e.g. the next “load more” would re-fetch from offset 0 and replace data
        // unexpectedly). Consider making load(pageSize:) return/throw on failure so reloadLoadedMeetings() can restore
        // futureOffset (and possibly coalesce missed reloads while isLoading is true).
        guard !isLoading else { return }
        isLoading = true
        hasError = false
        hasConversationNameUpdateError = false
        meetingPendingConversationNameUpdate = nil
        defer { isLoading = false }
        do {
            let meeting = try await saveMeeting()
            onSuccess(meeting)
        } catch let UpdateMeetingUseCaseError.conversationNameUpdateFailed(updatedMeeting) {
            meetingPendingConversationNameUpdate = updatedMeeting
            hasConversationNameUpdateError = true
        } catch {
            let errorType = Swift.type(of: error)
            WireLogger.search.error("failed to save meeting: \(String(describing: errorType))")
            hasError = true
        }
    }

    func retryConversationNameUpdate() async {
        guard !isLoading, let meeting = meetingPendingConversationNameUpdate else { return }
        isLoading = true
        hasConversationNameUpdateError = false
        defer { isLoading = false }

        do {
            try await updateMeetingUseCase.updateConversationName(for: meeting)
            meetingPendingConversationNameUpdate = nil
            onSuccess(meeting)
        } catch {
            let errorType = Swift.type(of: error)
            WireLogger.search.error("failed to update conversation name: \(String(describing: errorType))")
            hasConversationNameUpdateError = true
        }
    }

    // MARK: - Private

    /// The create modes create the meeting the same way; an instant meeting
    /// simply starts now and lasts one hour instead of using the schedule
    /// fields. Editing updates the existing meeting with the form values.
    private func saveMeeting() async throws -> Meeting {
        switch mode {
        case .instant:
            let startTime = currentDateProvider.now
            return try await createMeetingUseCase.invoke(
                title: meetingTitle,
                startTime: startTime,
                endTime: startTime.addingTimeInterval(TimeInterval.oneHour),
                recurrence: nil,
                participants: selectedMembers
            )
        case .scheduled:
            return try await createMeetingUseCase.invoke(
                title: meetingTitle,
                startTime: startDate,
                endTime: endDate,
                recurrence: repeatOption.toRecurrence(),
                participants: selectedMembers
            )
        case let .edit(meeting):
            return try await updateMeetingUseCase.invoke(
                meeting: meeting,
                title: meetingTitle,
                startTime: startDate,
                endTime: endDate,
                recurrence: repeatOption.toRecurrence(),
                participants: selectedMembers
            )
        }
    }

    private static func editableTimeRange(for meeting: Meeting, now: Date) -> (start: Date, end: Date) {
        guard meeting.recurrence != nil, meeting.start < now else {
            return (meeting.start, meeting.end)
        }

        guard let nextOccurrence = MeetingOccurrencePaginator()
            .occurrences(for: [meeting], startingAt: now, offset: 0, limit: 1)
            .first else {
            return (meeting.start, meeting.end)
        }

        return (nextOccurrence.start, nextOccurrence.end)
    }

    private static func nextSelectableStartDate(after date: Date) -> Date {
        let rounded = date.roundedUpToNextMinuteInterval(timePickerMinuteInterval)
        return rounded > date ? rounded : rounded.addingTimeInterval(minimumDuration)
    }

    private static func adjustedEndDate(
        _ proposedEndDate: Date,
        forStartDate startDate: Date,
        calendar: Calendar = .current
    ) -> Date {
        // The hard limit is independent from the start time: no end time past 23:45 on the selected start date.
        let latestEndDate = latestEndDate(for: startDate, calendar: calendar)
        if proposedEndDate > latestEndDate {
            return latestEndDate
        }

        let proposedTimeComponents = calendar.dateComponents(
            [.hour, .minute, .second, .nanosecond],
            from: proposedEndDate
        )
        var endDateComponents = calendar.dateComponents([.year, .month, .day], from: startDate)
        endDateComponents.hour = proposedTimeComponents.hour
        endDateComponents.minute = proposedTimeComponents.minute
        endDateComponents.second = proposedTimeComponents.second
        endDateComponents.nanosecond = proposedTimeComponents.nanosecond

        let endDateOnStartDay = calendar.date(from: endDateComponents) ?? proposedEndDate
        let earliestEndDate = min(startDate.addingTimeInterval(minimumDuration), latestEndDate)

        return min(max(endDateOnStartDay, earliestEndDate), latestEndDate)
    }

    private static func latestEndDate(for startDate: Date, calendar: Calendar = .current) -> Date {
        var components = calendar.dateComponents([.year, .month, .day], from: startDate)
        components.hour = 23
        components.minute = 45
        components.second = 0
        components.nanosecond = 0

        return calendar.date(from: components) ?? calendar.startOfDay(for: startDate).addingTimeInterval(
            TimeInterval.oneDay - TimeInterval(timePickerMinuteInterval) * TimeInterval.oneMinute
        )
    }

}

private extension Date {

    /// Returns the date rounded up to the next interval boundary
    /// (e.g. 10:02 -> 10:15 for a 15-minute interval). Dates already
    /// on a boundary are returned unchanged.
    func roundedUpToNextMinuteInterval(_ minuteInterval: Int, calendar: Calendar = .current) -> Date {
        precondition(minuteInterval > 0 && 60.isMultiple(of: minuteInterval))

        let components = calendar.dateComponents([.minute, .second, .nanosecond], from: self)
        let minutesPastBoundary = (components.minute ?? 0) % minuteInterval
        let secondsPastBoundary = TimeInterval(minutesPastBoundary) * .oneMinute
            + TimeInterval(components.second ?? 0)
            + TimeInterval(components.nanosecond ?? 0) / 1_000_000_000

        guard secondsPastBoundary > 0 else { return self }

        return addingTimeInterval(TimeInterval(minuteInterval) * .oneMinute - secondsPastBoundary)
    }

}

private extension MeetingRepeatOption {

    /// Inverse of `toRecurrence()`, for pre-filling the repeat picker when
    /// editing. Recurrences the picker can't represent (e.g. an interval
    /// other than 1, 2, or 4 for weekly) collapse to the option with the
    /// same frequency, so saving may normalize an exotic recurrence.
    init(recurrence: MeetingRecurrence?) {
        self = switch (recurrence?.frequency, recurrence?.interval) {
        case (nil, _): .never
        case (.daily, _): .daily
        case (.weekly, 2): .everyTwoWeeks
        case (.weekly, 4): .everyFourWeeks
        case (.weekly, _): .weekly
        case (.monthly, _): .monthly
        case (.yearly, _): .yearly
        }
    }

    func toRecurrence() -> MeetingRecurrence? {
        switch self {
        case .never: nil
        case .daily: MeetingRecurrence(frequency: .daily, interval: 1)
        case .weekly: MeetingRecurrence(frequency: .weekly, interval: 1)
        case .everyTwoWeeks: MeetingRecurrence(frequency: .weekly, interval: 2)
        case .everyFourWeeks: MeetingRecurrence(frequency: .weekly, interval: 4)
        case .monthly: MeetingRecurrence(frequency: .monthly, interval: 1)
        case .yearly: MeetingRecurrence(frequency: .yearly, interval: 1)
        }
    }

}
