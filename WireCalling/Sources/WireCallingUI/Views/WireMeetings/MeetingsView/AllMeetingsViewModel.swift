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

import SwiftUI
import WireCallingDomainSupport
import WireLogging

/// ViewModel responsible for the AllMeetingsView screen.
/// Owns the MeetingsViewModel for data logic and handles navigation actions.
@Observable
@MainActor
package final class AllMeetingsViewModel {

    private let makeFormViewModel: @MainActor (
        _ mode: MeetingFormViewModel.Mode,
        _ onSuccess: @escaping (Meeting) -> Void
    ) -> MeetingFormViewModel

    package let meetingsViewModel: MeetingsViewModel

    var presentedFormMode: MeetingFormViewModel.Mode?
    var hasJoinError = false

    private let joinMeetingCallUseCase: (any JoinMeetingCallUseCaseProtocol)?

    package init(
        currentDateProvider: any CurrentDateProviding,
        formatter: MeetingsFormatter = MeetingsFormatter(),
        upcomingMeetingsUseCase: any FetchUpcomingMeetingsUseCaseProtocol,
        observeMeetingChangesUseCase: any ObserveMeetingChangesUseCaseProtocol,
        deleteMeetingUseCase: any DeleteMeetingUseCaseProtocol,
        observeAttendedMeetingsUseCase: (any ObserveAttendedMeetingsUseCaseProtocol)? = nil,
        joinMeetingCallUseCase: (any JoinMeetingCallUseCaseProtocol)? = nil,
        makeFormViewModel: @escaping @MainActor (
            _ mode: MeetingFormViewModel.Mode,
            _ onSuccess: @escaping (Meeting) -> Void
        ) -> MeetingFormViewModel
    ) {
        self.meetingsViewModel = MeetingsViewModel(
            currentDateProvider: currentDateProvider,
            formatter: formatter,
            upcomingMeetingsUseCase: upcomingMeetingsUseCase,
            observeMeetingChangesUseCase: observeMeetingChangesUseCase,
            deleteMeetingUseCase: deleteMeetingUseCase,
            observeAttendedMeetingsUseCase: observeAttendedMeetingsUseCase
        )
        self.joinMeetingCallUseCase = joinMeetingCallUseCase
        self.makeFormViewModel = makeFormViewModel
    }

    // MARK: - Public Interface

    func createInstantMeetingTapped() {
        presentedFormMode = .instant
    }

    func scheduleMeetingTapped() {
        presentedFormMode = .scheduled
    }

    func editMeetingTapped(_ meeting: Meeting) {
        presentedFormMode = .edit(meeting)
    }

    /// The user tapped "Join" on the meeting that is taking place right now.
    ///
    /// The call screen is presented by the app's call state observer once the call
    /// is entered, so there is nothing to present from here.
    func joinMeetingTapped(_ occurrence: MeetingOccurrence) {
        guard let joinMeetingCallUseCase else { return }

        Task {
            do {
                try await joinMeetingCallUseCase.invoke(conversationID: occurrence.conversationID)
            } catch {
                hasJoinError = true
                WireLogger.meetings.error("failed to join meeting call: \(String(reflecting: error))")
            }
        }
    }

    func makeMeetingFormViewModel(mode: MeetingFormViewModel.Mode) -> MeetingFormViewModel {
        makeFormViewModel(mode) { [weak self] _ in
            self?.presentedFormMode = nil
        }
    }

}
