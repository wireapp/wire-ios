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

    private let joinMeetingCallUseCase: any JoinMeetingCallUseCaseProtocol

    package init(
        currentDateProvider: any CurrentDateProviding,
        formatter: MeetingsFormatter = MeetingsFormatter(),
        upcomingMeetingsUseCase: any FetchUpcomingMeetingsUseCaseProtocol,
        observeMeetingChangesUseCase: any ObserveMeetingChangesUseCaseProtocol,
        deleteMeetingUseCase: any DeleteMeetingUseCaseProtocol,
        selfUserID: UUID,
        observeAttendedMeetingsUseCase: (any ObserveAttendedMeetingsUseCaseProtocol)? = nil,
        joinMeetingCallUseCase: any JoinMeetingCallUseCaseProtocol,
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
            selfUserID: selfUserID,
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

    func joinMeetingTapped(_ occurrence: MeetingOccurrence) async {
        await joinCall(conversationID: occurrence.conversationID)
    }

    func makeMeetingFormViewModel(mode: MeetingFormViewModel.Mode) -> MeetingFormViewModel {
        makeFormViewModel(mode) { [weak self] meeting in
            guard let self else { return }
            presentedFormMode = nil
            if case .instant = mode {
                Task { await self.joinCall(conversationID: meeting.conversationID) }
            }
        }
    }

    // MARK: - Private Helpers

    private func joinCall(conversationID: QualifiedID) async {
        do {
            try await joinMeetingCallUseCase.invoke(conversationID: conversationID)
        } catch {
            hasJoinError = true
            WireLogger.meetings.error("failed to join meeting call: \(String(reflecting: error))")
        }
    }

}
