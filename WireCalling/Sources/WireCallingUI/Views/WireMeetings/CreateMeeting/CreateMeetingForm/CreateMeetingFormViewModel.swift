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
import WireCallingDomain

@Observable
@MainActor
final class CreateMeetingFormViewModel {

    /// Determines whether the meeting starts immediately on submit or is
    /// scheduled for a future date and time. Drives the form layout
    /// (schedule fields appear only in `.scheduled`), the navigation title,
    /// and the primary action button's label and behavior.
    enum Mode: Hashable, Identifiable {

        /// Start the meeting immediately. The schedule section
        /// (start/end/repeat) is hidden; the action button reads "Start" and
        /// the screen is titled "Meet Now".
        case instant

        /// Schedule the meeting for a future date and time. The schedule
        /// section is visible; the action button reads "Schedule" and the
        /// screen is titled "Schedule a meeting".
        case scheduled

        var id: Self { self }
    }

    let mode: Mode
    let memberRepository: any MemberRepositoryProtocol
    private let createMeetingUseCase: any CreateMeetingUseCaseProtocol
    private let onSuccess: (Meeting) -> Void

    var meetingTitle: String = ""
    var startDate: Date = .init()
    var endDate: Date = .init().addingTimeInterval(1800)
    var repeatOption: RepeatOption = .never
    var selectedMembers: [Member] = []
    var isLoading = false
    var error: (any Error)?

    var selectedMembersSummary: String {
        selectedMembers
            .map(\.name)
            .joined(separator: ", ")
    }

    var isNextButtonEnabled: Bool {
        !meetingTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Public Interface

    init(
        mode: Mode,
        memberRepository: any MemberRepositoryProtocol,
        createMeetingUseCase: any CreateMeetingUseCaseProtocol,
        onSuccess: @escaping (Meeting) -> Void = { _ in }
    ) {
        self.mode = mode
        self.memberRepository = memberRepository
        self.createMeetingUseCase = createMeetingUseCase
        self.onSuccess = onSuccess
    }

    func clearTitle() {
        meetingTitle = ""
    }

    func makeMemberSelectionViewModel() -> MemberSelectionViewModel {
        MemberSelectionViewModel(
            source: memberRepository,
            initialSelection: selectedMembers,
            onSelect: { [weak self] in self?.selectedMembers = $0 }
        )
    }

    func submit() {
        guard !isLoading else { return }
        Task {
            switch mode {
            case .instant:
                await createInstantMeeting()
            case .scheduled:
                await scheduleMeeting()
            }
        }
    }

    // MARK: - Private

    private func createInstantMeeting() async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        let now = Date()
        do {
            let meeting = try await createMeetingUseCase.execute(
                title: meetingTitle,
                startTime: now,
                endTime: now.addingTimeInterval(1800),
                repeatOption: .never
            )
            onSuccess(meeting)
        } catch {
            self.error = error
        }
    }

    private func scheduleMeeting() async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            let meeting = try await createMeetingUseCase.execute(
                title: meetingTitle,
                startTime: startDate,
                endTime: endDate,
                repeatOption: repeatOption
            )
            onSuccess(meeting)
        } catch {
            self.error = error
        }
    }

}
