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
import UIKit
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
    private let supportsMeetingLinks: Bool
    let searchMembersUseCase: any SearchMembersUseCaseProtocol
    private let createMeetingUseCase: any CreateMeetingUseCaseProtocol
    private let updateMeetingUseCase: any UpdateMeetingUseCaseProtocol
    private let currentDateProvider: any CurrentDateProviding
    private let onSuccess: (Meeting) -> Void
    private let fetchMeetingLink: (@Sendable (QualifiedID) async throws -> MeetingLink?)?
    private let refreshMeetingLink: (@Sendable (QualifiedID, String?) async throws -> MeetingLink?)?
    var presentedLink: MeetingLinkViewModel?

    var canChangeMeetingLink: Bool { mode.isEdit && fetchMeetingLink != nil && refreshMeetingLink != nil }

    func meetingLinkTapped() {
        guard case let .edit(meeting) = mode, let fetchMeetingLink, let refreshMeetingLink else { return }
        presentedLink = MeetingLinkViewModel(
            fetchLink: { try await fetchMeetingLink(meeting.id) },
            refreshLink: { try await refreshMeetingLink(meeting.id, $0) }
        )
    }

    private static let timePickerMinuteInterval = 15
    // Match the limits enforced by SimpleTextFieldValidator for conversation names.
    private static let maximumConversationNameLength = 64
    private static let maximumConversationNameByteLength = 256

    /// The smallest selectable interval between start and end time.
    private static let minimumDuration = TimeInterval(timePickerMinuteInterval) * TimeInterval.oneMinute

    var meetingTitle: String = ""
    var password: String = ""
    var confirmPassword: String = ""

    static let minimumPasswordLength = 8
    private static let passwordCharacterGroups = [
        "abcdefghijklmnopqrstuvwxyz",
        "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
        "0123456789",
        "!@#$%^&*()-_+=<>?/[]{|}"
    ]

    var canSetPassword: Bool { supportsMeetingLinks && mode == .scheduled }

    var passwordsMatch: Bool {
        !canSetPassword || password.unicodeScalars.elementsEqual(confirmPassword.unicodeScalars)
    }

    var isPasswordValid: Bool {
        !canSetPassword || Self.isPasswordValid(password)
    }

    static func isPasswordValid(_ password: String) -> Bool {
        guard !password.isEmpty else { return true }
        let characterSets: [CharacterSet] = [
            .lowercaseLetters,
            .uppercaseLetters,
            .decimalDigits,
            .alphanumerics.inverted
        ]
        return (Self.minimumPasswordLength ... 1024).contains(password.unicodeScalars.count) &&
            characterSets.allSatisfy { password.rangeOfCharacter(from: $0) != nil }
    }

    func generatePassword() {
        password = Self.makePassword()
        confirmPassword = password
    }

    static func makePassword() -> String {
        let groups = Self.passwordCharacterGroups
        let allCharacters = groups.joined()
        var characters = groups.map { $0.randomElement()! }
        while characters.count < Self.minimumPasswordLength {
            characters.append(allCharacters.randomElement()!)
        }
        return String(characters.shuffled())
    }

    func copyPassword(to pasteboard: UIPasteboard = .general) {
        guard !password.isEmpty, isPasswordValid else { return }
        pasteboard.string = password
    }

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
    /// Edited meetings may start up to 24 hours in the past, as allowed by the backend.
    var startDateRange: PartialRangeFrom<Date> {
        let earliest = currentDateProvider.now
        if case .scheduled = mode {
            return Self.nextSelectableStartDate(after: earliest)...
        }
        if case .edit = mode {
            return earliest.addingTimeInterval(-TimeInterval.oneDay)...
        }
        return Calendar.current.startOfDay(for: earliest)...
    }

    /// Present a valid picker selection without changing the meeting merely by opening the picker.
    /// The form displays `startDate`; only a valid picker change updates it.
    var startDatePickerSelection: Date {
        get { max(startDate, startDateRange.lowerBound) }
        set {
            guard startDateRange.contains(newValue) else { return }
            startDate = newValue
        }
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
    var invitedEmails: [String] = []
    private var originalInvitedEmails: [String]?
    private(set) var isLoadingInvitedEmails = false
    private(set) var hasEmailLoadError = false

    var allowsEmailInvitations: Bool { supportsMeetingLinks && mode != .instant }
    var needsInvitedEmails: Bool { allowsEmailInvitations && mode.isEdit && originalInvitedEmails == nil }
    var selectedParticipantCount: Int { selectedMembers.count + invitedEmails.count }
    private(set) var isLoading = false

    var hasError = false
    private var submitError: (any Error)?

    var dismissAfterError: Bool {
        switch submitError {
        case CreateMeetingUseCaseError.missingLink?,
             CreateMeetingUseCaseError.conversationSetupFailed?,
             CreateMeetingUseCaseError.addParticipantsFailed?,
             UpdateMeetingUseCaseError.addParticipantsFailed?,
             UpdateMeetingUseCaseError.removeParticipantsFailed?,
             UpdateMeetingUseCaseError.emailInvitationsFailed?:
            true
        default:
            false
        }
    }

    var errorTitle: String {
        typealias Errors = L10n.Localizable.Meetings
        switch submitError {
        case CreateMeetingUseCaseError.missingLink?:
            return L10n.Localizable.WireMeetings.Schedule.ParticipantsNotAdded.createdTitle
        case CreateMeetingUseCaseError.conversationSetupFailed?, CreateMeetingUseCaseError.addParticipantsFailed?:
            return Errors.Error.setupFailedTitle
        default:
            break
        }
        switch mode {
        case .instant: return Errors.MeetNowModal.Error.createFailedTitle
        case .scheduled: return Errors.ScheduleModal.Error.createFailedTitle
        case .edit: return Errors.ScheduleModal.Error.updateFailedTitle
        }
    }

    var errorMessage: String {
        typealias Errors = L10n.Localizable.Meetings
        switch submitError {
        case CreateMeetingUseCaseError.missingLink?:
            return Errors.Error.missingLink
        case let CreateMeetingUseCaseError.conversationSetupFailed(hasLink)?:
            return Errors.Error.conversationSetupFailed + missingLinkMessage(hasLink: hasLink)
        case let CreateMeetingUseCaseError.addParticipantsFailed(participants, reasons, hasLink)?:
            let details = MeetingParticipantErrorFormatter.message(participants: participants, reasons: reasons)
            return Errors.Error.addParticipantsFailed + (details.isEmpty ? "" : "\n\n" + details)
                + missingLinkMessage(hasLink: hasLink)
        case let UpdateMeetingUseCaseError.addParticipantsFailed(participants, reasons)?:
            let details = MeetingParticipantErrorFormatter.message(participants: participants, reasons: reasons)
            return Errors.Error.addParticipantsFailed + (details.isEmpty ? "" : "\n\n" + details)
        case let UpdateMeetingUseCaseError.removeParticipantsFailed(participants)?:
            return Errors.ScheduleModal.Error.removeParticipantsFailed + participantFailureDetails(for: participants)
        case UpdateMeetingUseCaseError.emailInvitationsFailed?:
            return L10n.Localizable.WireMeetings.Schedule.Email.saveFailed
        case UpdateMeetingUseCaseError.conversationNotResolved?:
            return Errors.ScheduleModal.Error.editMeetingIdMissing
        default:
            switch mode {
            case .instant: return Errors.MeetNowModal.Error.createFailed
            case .scheduled: return Errors.ScheduleModal.Error.createFailed
            case .edit: return Errors.ScheduleModal.Error.updateFailed
            }
        }
    }

    var hasExpiredStartDateError = false

    /// Set when the meeting was saved but its dedicated conversation could not be renamed.
    var hasConversationNameUpdateError = false
    private var meetingPendingConversationNameUpdate: Meeting?

    var hasParticipantsNotAddedAlert = false
    private(set) var participantsNotAdded: [MeetingMember] = []
    private var meetingWithParticipantsNotAdded: Meeting?
    private var participantMeetingHasLink = true
    private var didCompleteSavedMeeting = false

    var conversationNameErrorMessage: String {
        L10n.Localizable.WireMeetings.Schedule.Error.ConversationName.message
            + participantFailureDetails(for: participantsNotAdded)
            + (dismissAfterError ? "\n\n" + errorMessage : "")
    }

    var participantsNotAddedMessage: String {
        MeetingParticipantErrorFormatter.message(participants: participantsNotAdded, reasons: [:])
            + missingLinkMessage(hasLink: participantMeetingHasLink)
    }

    private func missingLinkMessage(hasLink: Bool) -> String {
        supportsMeetingLinks && !hasLink ? "\n\n" + L10n.Localizable.Meetings.Error.missingLink : ""
    }

    private func participantFailureDetails(for participants: [MeetingMember]) -> String {
        guard !participants.isEmpty else { return "" }
        return "\n\n" + L10n.Localizable.Meetings.ScheduleModal.Error.addParticipantsFailed + "\n\n"
            + MeetingParticipantErrorFormatter.message(participants: participants, reasons: [:])
    }

    var selectedMembersSummary: String {
        (selectedMembers.map(\.name) + invitedEmails).joined(separator: ", ")
    }

    var isNextButtonEnabled: Bool {
        !meetingTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty && !isMeetingTitleTooLong && !needsInvitedEmails && isPasswordValid && passwordsMatch
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
        supportsMeetingLinks: Bool = false,
        fetchMeetingLink: (@Sendable (QualifiedID) async throws -> MeetingLink?)? = nil,
        refreshMeetingLink: (@Sendable (QualifiedID, String?) async throws -> MeetingLink?)? = nil,
        onSuccess: @escaping (Meeting) -> Void = { _ in }
    ) {
        self.mode = mode
        self.supportsMeetingLinks = supportsMeetingLinks
        self.searchMembersUseCase = searchMembersUseCase
        self.createMeetingUseCase = createMeetingUseCase
        self.updateMeetingUseCase = updateMeetingUseCase
        self.currentDateProvider = currentDateProvider
        self.onSuccess = onSuccess
        self.fetchMeetingLink = fetchMeetingLink
        self.refreshMeetingLink = refreshMeetingLink

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
            onSelect: { [weak self] in self?.selectedMembers = $0 },
            allowsEmailInvitations: allowsEmailInvitations,
            initialEmailSelection: invitedEmails,
            onSelectEmails: { [weak self] in self?.invitedEmails = $0 }
        )
    }

    func loadInvitedEmails() async {
        guard needsInvitedEmails, !isLoadingInvitedEmails, case let .edit(meeting) = mode else { return }
        isLoadingInvitedEmails = true
        hasEmailLoadError = false
        defer { isLoadingInvitedEmails = false }
        do {
            let emails = try await updateMeetingUseCase.fetchInvitedEmails(for: meeting)
            try Task.checkCancellation()
            originalInvitedEmails = emails
            invitedEmails = emails
        } catch {
            guard !Task.isCancelled else { return }
            hasEmailLoadError = true
        }
    }

    func submit() async {
        // TODO: [WPB-20274] reloadLoadedMeetings() sets futureOffset = 0 before calling load(pageSize:), but
        // load(pageSize:) catches errors internally and does not restore the previous offset on failure. If the fetch
        // throws, futureOffset stays at 0 while loadedMeetings still contains the previously loaded page(s), which can
        // corrupt subsequent pagination (e.g. the next “load more” would re-fetch from offset 0 and replace data
        // unexpectedly). Consider making load(pageSize:) return/throw on failure so reloadLoadedMeetings() can restore
        // futureOffset (and possibly coalesce missed reloads while isLoading is true).
        guard !isLoading, !needsInvitedEmails, meetingWithParticipantsNotAdded == nil,
              !dismissAfterError, isPasswordValid, passwordsMatch else { return }
        hasError = false
        submitError = nil
        hasConversationNameUpdateError = false
        meetingPendingConversationNameUpdate = nil
        participantsNotAdded = []
        hasExpiredStartDateError = false
        if mode.isEdit, startDate < currentDateProvider.now.addingTimeInterval(-TimeInterval.oneDay) {
            hasExpiredStartDateError = true
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            let meeting = try await saveMeeting()
            onSuccess(meeting)
        } catch let CreateMeetingUseCaseError.participantsNotAdded(result, participants) {
            password = ""
            confirmPassword = ""
            participantMeetingHasLink = result.link != nil
            meetingWithParticipantsNotAdded = result.meeting
            participantsNotAdded = participants
            hasParticipantsNotAddedAlert = true
        } catch let UpdateMeetingUseCaseError.participantsNotAdded(meeting, participants) {
            meetingWithParticipantsNotAdded = meeting
            participantsNotAdded = participants
            hasParticipantsNotAddedAlert = true
        } catch let UpdateMeetingUseCaseError.conversationNameUpdateFailed(updatedMeeting, participants) {
            meetingPendingConversationNameUpdate = updatedMeeting
            participantsNotAdded = participants
            hasConversationNameUpdateError = true
        } catch {
            if error is CreateMeetingUseCaseError {
                password = ""
                confirmPassword = ""
            }
            let errorType = Swift.type(of: error)
            WireLogger.search.error("failed to save meeting: \(String(describing: errorType))")
            submitError = error
            if case let .emailInvitationsFailed(updatedMeeting)? = error as? UpdateMeetingUseCaseError {
                originalInvitedEmails = nil
                await loadInvitedEmails()
                if case let .edit(original) = mode, updatedMeeting.title != original.title {
                    do {
                        try await updateMeetingUseCase.updateConversationName(for: updatedMeeting)
                    } catch {
                        meetingPendingConversationNameUpdate = updatedMeeting
                        hasConversationNameUpdateError = true
                        return
                    }
                }
            }
            hasError = true
        }
    }

    func acknowledgeError(dismiss: () -> Void) {
        if case let CreateMeetingUseCaseError.missingLink(meeting)? = submitError {
            guard !didCompleteSavedMeeting else { return }
            didCompleteSavedMeeting = true
            hasError = false
            onSuccess(meeting)
        } else if dismissAfterError {
            dismiss()
        }
    }

    func acknowledgeParticipantsNotAdded() {
        guard !didCompleteSavedMeeting, let meeting = meetingWithParticipantsNotAdded else { return }
        didCompleteSavedMeeting = true
        hasParticipantsNotAddedAlert = false
        onSuccess(meeting)
    }

    func retryConversationNameUpdate() async {
        guard !isLoading, let meeting = meetingPendingConversationNameUpdate else { return }
        isLoading = true
        hasConversationNameUpdateError = false
        defer { isLoading = false }

        do {
            try await updateMeetingUseCase.updateConversationName(for: meeting)
            meetingPendingConversationNameUpdate = nil
            if dismissAfterError {
                hasError = true
            } else if participantsNotAdded.isEmpty {
                onSuccess(meeting)
            } else {
                meetingWithParticipantsNotAdded = meeting
                hasParticipantsNotAddedAlert = true
            }
        } catch {
            let errorType = Swift.type(of: error)
            WireLogger.search.error("failed to update conversation name: \(String(describing: errorType))")
            hasConversationNameUpdateError = true
        }
    }

    // MARK: - Private

    /// Creation sends an explicit type. Immediate meetings start now and last one hour.
    /// Editing updates the existing meeting with the form values.
    private func saveMeeting() async throws -> Meeting {
        switch mode {
        case .instant:
            let startTime = currentDateProvider.now
            let result = try await createMeetingUseCase.invoke(
                title: meetingTitle,
                startTime: startTime,
                endTime: startTime.addingTimeInterval(TimeInterval.oneHour),
                recurrence: nil,
                type: .immediate,
                password: nil,
                participants: selectedMembers,
                invitedEmails: []
            )
            return try completeCreation(result)
        case .scheduled:
            let result = try await createMeetingUseCase.invoke(
                title: meetingTitle,
                startTime: startDate,
                endTime: endDate,
                recurrence: repeatOption.toRecurrence(),
                type: .scheduled,
                password: canSetPassword && !password.isEmpty ? password : nil,
                participants: selectedMembers,
                invitedEmails: allowsEmailInvitations ? invitedEmails : []
            )
            return try completeCreation(result)
        case let .edit(meeting):
            let original = allowsEmailInvitations ? originalInvitedEmails ?? [] : []
            let selected = allowsEmailInvitations ? invitedEmails : []
            let originalKeys = Set(original.map { $0.lowercased() })
            let selectedKeys = Set(selected.map { $0.lowercased() })
            return try await updateMeetingUseCase.invoke(
                meeting: meeting,
                title: meetingTitle,
                startTime: startDate,
                endTime: endDate,
                recurrence: repeatOption.toRecurrence(),
                participants: selectedMembers,
                emailsToAdd: selected.filter { !originalKeys.contains($0.lowercased()) },
                emailsToRemove: original.filter { !selectedKeys.contains($0.lowercased()) }
            )
        }
    }

    private func completeCreation(_ result: MeetingCreationResult) throws -> Meeting {
        password = ""
        confirmPassword = ""
        guard !supportsMeetingLinks || result.link != nil else {
            throw CreateMeetingUseCaseError.missingLink(meeting: result.meeting)
        }
        return result.meeting
    }

    private static func editableTimeRange(for meeting: Meeting, now: Date) -> (start: Date, end: Date) {
        let earliestStart = now.addingTimeInterval(-TimeInterval.oneDay)
        guard meeting.recurrence != nil, meeting.start < earliestStart else {
            return (meeting.start, meeting.end)
        }

        guard let nextOccurrence = MeetingOccurrencePaginator()
            .occurrences(for: [meeting], startingAt: earliestStart, offset: 0, limit: 1)
            .first else {
            return (meeting.start, meeting.end)
        }

        return (nextOccurrence.start, nextOccurrence.end)
    }

    private static func nextSelectableStartDate(after date: Date) -> Date {
        let rounded = date.roundedUpToNextMinuteInterval(timePickerMinuteInterval)
        let start = rounded > date ? rounded : rounded.addingTimeInterval(minimumDuration)
        // A 23:45 start has no later end on the same day. Use the next midnight instead.
        if start.addingTimeInterval(minimumDuration) > latestEndDate(for: start) {
            return Calendar.current.startOfDay(for: start.addingTimeInterval(minimumDuration))
        }
        return start
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
