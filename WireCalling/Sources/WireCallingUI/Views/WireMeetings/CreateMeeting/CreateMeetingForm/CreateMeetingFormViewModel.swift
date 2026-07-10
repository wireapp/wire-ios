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
package final class CreateMeetingFormViewModel {

    /// Determines whether the meeting starts immediately on submit or is
    /// scheduled for a future date and time. Drives the form layout
    /// (schedule fields appear only in `.scheduled`), the navigation title,
    /// and the primary action button's label and behavior.
    package enum Mode: Hashable, Identifiable {

        /// Start the meeting immediately. The schedule section
        /// (start/end/repeat) is hidden; the action button reads "Start" and
        /// the screen is titled "Meet Now".
        case instant

        /// Schedule the meeting for a future date and time. The schedule
        /// section is visible; the action button reads "Schedule" and the
        /// screen is titled "Schedule a meeting".
        case scheduled

        package var id: Self { self }
    }

    let mode: Mode
    let searchMembersUseCase: any SearchMembersUseCaseProtocol
    private let createInstantMeetingUseCase: any CreateInstantMeetingUseCaseProtocol
    private let createScheduledMeetingUseCase: any CreateScheduledMeetingUseCaseProtocol
    private let currentDateProvider: any CurrentDateProviding
    private let onSuccess: (Meeting) -> Void

    /// The smallest allowed interval between start and end date, matching
    /// the minute granularity of the time picker.
    private static let minimumDuration: TimeInterval = .oneMinute

    var meetingTitle: String = ""

    /// Changing the start date shifts the end date by the same amount,
    /// so the meeting duration is preserved.
    var startDate: Date {
        didSet {
            endDate = endDate.addingTimeInterval(startDate.timeIntervalSince(oldValue))
        }
    }

    /// The end date is always after the start date.
    var endDate: Date {
        didSet {
            if endDate < startDate.addingTimeInterval(Self.minimumDuration) {
                endDate = startDate.addingTimeInterval(Self.minimumDuration)
            }
        }
    }

    /// Meetings can't be scheduled on a past day, but any time
    /// of the current day is allowed.
    var startDateRange: PartialRangeFrom<Date> {
        Calendar.current.startOfDay(for: currentDateProvider.now)...
    }

    /// The end date must always be after the start date.
    var endDateRange: PartialRangeFrom<Date> {
        startDate.addingTimeInterval(Self.minimumDuration)...
    }

    var repeatOption: MeetingRepeatOption = .never
    var selectedMembers: [MeetingMember] = []
    private(set) var isLoading = false

    /// Set when creating a meeting fails. The caught error itself is only
    /// logged; the view shows a generic alert.
    var hasError = false

    var selectedMembersSummary: String {
        selectedMembers
            .map(\.name)
            .joined(separator: ", ")
    }

    var isNextButtonEnabled: Bool {
        !meetingTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Public Interface

    package init(
        mode: Mode,
        searchMembersUseCase: any SearchMembersUseCaseProtocol,
        createInstantMeetingUseCase: any CreateInstantMeetingUseCaseProtocol,
        createScheduledMeetingUseCase: any CreateScheduledMeetingUseCaseProtocol,
        currentDateProvider: any CurrentDateProviding,
        onSuccess: @escaping (Meeting) -> Void = { _ in }
    ) {
        self.mode = mode
        self.searchMembersUseCase = searchMembersUseCase
        self.createInstantMeetingUseCase = createInstantMeetingUseCase
        self.createScheduledMeetingUseCase = createScheduledMeetingUseCase
        self.currentDateProvider = currentDateProvider
        self.onSuccess = onSuccess

        let startDate = currentDateProvider.now.roundedUpToNextHalfHour()
        self.startDate = startDate
        self.endDate = startDate.addingTimeInterval(30 * TimeInterval.oneMinute)
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
        // TODO: [WPB-20274] reloadLoadedMeetings() sets futureOffset = 0 before calling load(pageSize:), but load(pageSize:) catches errors internally and does not restore the previous offset on failure. If the fetch throws, futureOffset stays at 0 while loadedMeetings still contains the previously loaded page(s), which can corrupt subsequent pagination (e.g. the next “load more” would re-fetch from offset 0 and replace data unexpectedly). Consider making load(pageSize:) return/throw on failure so reloadLoadedMeetings() can restore futureOffset (and possibly coalesce missed reloads while isLoading is true).
        guard !isLoading else { return }
        isLoading = true
        hasError = false
        defer { isLoading = false }
        switch mode {
        case .instant:
            await createInstantMeeting()
        case .scheduled:
            await scheduleMeeting()
        }
    }

    // MARK: - Private

    private func createInstantMeeting() async {
        do {
            let meeting = try await createInstantMeetingUseCase.invoke(
                title: meetingTitle,
                participants: selectedMembers
            )
            onSuccess(meeting)
        } catch {
            let errorType = Swift.type(of: error)
            WireLogger.search.error("failed to create instant meeting: \(String(describing: errorType))")
            hasError = true
        }
    }

    private func scheduleMeeting() async {
        do {
            let meeting = try await createScheduledMeetingUseCase.invoke(
                title: meetingTitle,
                startTime: startDate,
                endTime: endDate,
                recurrence: repeatOption.toRecurrence()
            )
            onSuccess(meeting)
        } catch {
            let errorType = Swift.type(of: error)
            WireLogger.search.error("failed to create instant meeting: \(String(describing: errorType))")
            hasError = true
        }
    }

}

private extension Date {

    /// Returns the date rounded up to the next half-hour boundary
    /// (e.g. 10:12 -> 10:30, 10:42 -> 11:00). Dates already on a
    /// boundary are returned unchanged.
    func roundedUpToNextHalfHour(calendar: Calendar = .current) -> Date {
        let components = calendar.dateComponents([.minute, .second], from: self)
        // How far past the last half-hour boundary this date is:
        // minutes past the boundary (minute % 30) converted to seconds, plus the seconds.
        let minutesPastBoundary = (components.minute ?? 0) % 30
        let secondsPastBoundary = TimeInterval(minutesPastBoundary) * .oneMinute + TimeInterval(components.second ?? 0)
        // Exactly on a boundary — nothing to round.
        guard secondsPastBoundary > 0 else { return self }
        // Add the remaining time up to the next boundary.
        return addingTimeInterval(30 * .oneMinute - secondsPastBoundary)
    }

}

private extension MeetingRepeatOption {

    func toRecurrence() -> MeetingRecurrence? {
        switch self {
        case .never: nil
        case .daily: MeetingRecurrence(frequency: .daily, interval: 1)
        case .weekly: MeetingRecurrence(frequency: .weekly, interval: 1)
        case .every2Weeks: MeetingRecurrence(frequency: .weekly, interval: 2)
        case .monthly: MeetingRecurrence(frequency: .monthly, interval: 1)
        case .yearly: MeetingRecurrence(frequency: .yearly, interval: 1)
        }
    }

}
