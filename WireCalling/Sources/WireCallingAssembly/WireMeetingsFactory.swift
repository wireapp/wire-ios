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

public import UIKit
public import WireCallingDomain

import SwiftUI
import WireCallingUI
import WireFoundation

public struct WireMeetingsFactory {

    @MainActor
    public init() {}

    @MainActor
    public func makeMeetingsView(
        meetingRepository: any MeetingRepositoryProtocol,
        memberRepository: any MeetingMemberRepositoryProtocol,
        conversationRepository: any MeetingConversationRepositoryProtocol,
        callRepository: any MeetingCallRepositoryProtocol,
        accentColorState: WireMeetingsAccentColorState
    ) -> UIViewController {
        let createMeetingUseCase = CreateMeetingUseCase(
            meetingRepository: meetingRepository,
            conversationRepository: conversationRepository
        )
        let updateMeetingUseCase = UpdateMeetingUseCase(
            meetingRepository: meetingRepository,
            conversationRepository: conversationRepository
        )
        let fetchUpcomingMeetingsUseCase = FetchUpcomingMeetingsUseCase(
            repository: meetingRepository,
            currentDateProvider: .system
        )
        let observeMeetingChangesUseCase = ObserveMeetingChangesUseCase(repository: meetingRepository)
        let deleteMeetingUseCase = DeleteMeetingUseCase(repository: meetingRepository)
        let observeAttendedMeetingsUseCase = ObserveAttendedMeetingsUseCase(repository: callRepository)
        let joinMeetingCallUseCase = JoinMeetingCallUseCase(repository: callRepository)
        let searchMembersUseCase = SearchMembersUseCase(repository: memberRepository)
        let meetingsViewModel = AllMeetingsViewModel(
            currentDateProvider: .system,
            upcomingMeetingsUseCase: fetchUpcomingMeetingsUseCase,
            observeMeetingChangesUseCase: observeMeetingChangesUseCase,
            deleteMeetingUseCase: deleteMeetingUseCase,
            observeAttendedMeetingsUseCase: observeAttendedMeetingsUseCase,
            joinMeetingCallUseCase: joinMeetingCallUseCase,
            makeFormViewModel: { mode, onSuccess in
                MeetingFormViewModel(
                    mode: mode,
                    searchMembersUseCase: searchMembersUseCase,
                    createMeetingUseCase: createMeetingUseCase,
                    updateMeetingUseCase: updateMeetingUseCase,
                    currentDateProvider: .system,
                    onSuccess: onSuccess
                )
            }
        )
        return UIHostingController(
            rootView: AnyView(
                WireMeetingsRootView(
                    viewModel: meetingsViewModel,
                    accentColorState: accentColorState
                )
            )
        )
    }

}
