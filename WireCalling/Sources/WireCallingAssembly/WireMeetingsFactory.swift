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

public import Foundation
public import UIKit
public import WireCallingDomain

import SwiftUI
import WireCallingData
import WireCallingUI
import WireFoundation

public struct WireMeetingsFactory {

    private let selfUserID: UUID

    @MainActor
    public init(selfUserID: UUID) {
        self.selfUserID = selfUserID
    }

    @MainActor
    public func makeMeetingsView(
        meetingRepository: any MeetingRepositoryProtocol,
        memberRepository: any MeetingMemberRepositoryProtocol,
        conversationRepository: any MeetingConversationRepositoryProtocol,
        callRepository: any MeetingCallRepositoryProtocol,
        accentColorState: WireMeetingsAccentColorState
    ) -> UIViewController {
        #if DEBUG
            let uiTestConfig = UITestConfig.environment
            let currentDateProvider: any CurrentDateProviding = if let date = uiTestConfig?.meetingsDate {
                MeetingsUITestDateProvider(now: date)
            } else {
                .system
            }
        #else
            let currentDateProvider: any CurrentDateProviding = .system
        #endif

        let realCreateMeetingUseCase = CreateMeetingUseCase(
            meetingRepository: meetingRepository,
            conversationRepository: conversationRepository
        )
        #if DEBUG
            let createMeetingUseCase: any CreateMeetingUseCaseProtocol = if let failureID = uiTestConfig?
                .meetingsCreateFailureID {
                MeetingsUITestCreateUseCase(
                    wrapping: realCreateMeetingUseCase,
                    failureID: failureID
                )
            } else {
                realCreateMeetingUseCase
            }
        #else
            let createMeetingUseCase: any CreateMeetingUseCaseProtocol = realCreateMeetingUseCase
        #endif
        let updateMeetingUseCase = UpdateMeetingUseCase(
            meetingRepository: meetingRepository,
            conversationRepository: conversationRepository
        )
        let fetchUpcomingMeetingsUseCase = FetchUpcomingMeetingsUseCase(
            repository: meetingRepository,
            currentDateProvider: currentDateProvider
        )
        let observeMeetingChangesUseCase = ObserveMeetingChangesUseCase(repository: meetingRepository)
        let deleteMeetingUseCase = DeleteMeetingUseCase(
            meetingRepository: meetingRepository,
            conversationRepository: conversationRepository,
            cancelReminders: { accountID, meetingID in
                await MeetingReminderScheduler().cancelAll(accountID: accountID, meetingID: meetingID)
            },
            selfUserID: selfUserID
        )
        let observeAttendedMeetingsUseCase = ObserveAttendedMeetingsUseCase(repository: callRepository)
        let joinMeetingCallUseCase = JoinMeetingCallUseCase(repository: callRepository)
        let searchMembersUseCase = SearchMembersUseCase(repository: memberRepository)
        let meetingsViewModel = AllMeetingsViewModel(
            currentDateProvider: currentDateProvider,
            upcomingMeetingsUseCase: fetchUpcomingMeetingsUseCase,
            observeMeetingChangesUseCase: observeMeetingChangesUseCase,
            deleteMeetingUseCase: deleteMeetingUseCase,
            selfUserID: selfUserID,
            observeAttendedMeetingsUseCase: observeAttendedMeetingsUseCase,
            joinMeetingCallUseCase: joinMeetingCallUseCase,
            makeFormViewModel: { mode, onSuccess in
                MeetingFormViewModel(
                    mode: mode,
                    searchMembersUseCase: searchMembersUseCase,
                    createMeetingUseCase: createMeetingUseCase,
                    updateMeetingUseCase: updateMeetingUseCase,
                    currentDateProvider: currentDateProvider,
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

#if DEBUG
    private struct MeetingsUITestDateProvider: CurrentDateProviding {
        let now: Date
    }
#endif
