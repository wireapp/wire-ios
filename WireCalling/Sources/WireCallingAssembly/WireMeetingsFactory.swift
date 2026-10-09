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
        let currentDateProvider = makeCurrentDateProvider()

        let createMeetingUseCase = makeCreateMeetingUseCase(
            meetingRepository: meetingRepository,
            conversationRepository: conversationRepository
        )
        let updateMeetingUseCase = UpdateMeetingUseCase(
            meetingRepository: meetingRepository,
            conversationRepository: conversationRepository
        )
        let fetchUpcomingMeetingsUseCase = makeFetchUpcomingMeetingsUseCase(
            meetingRepository: meetingRepository,
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

    private func makeCurrentDateProvider() -> any CurrentDateProviding {
        #if DEBUG
            if let date = UITestConfig.environment?.meetingsDate {
                return MeetingsUITestDateProvider(now: date, clockID: UITestConfig.environment?.meetingsClockID)
            }
        #endif
        return .system
    }

    private func makeCreateMeetingUseCase(
        meetingRepository: any MeetingRepositoryProtocol,
        conversationRepository: any MeetingConversationRepositoryProtocol
    ) -> any CreateMeetingUseCaseProtocol {
        let createUseCase = CreateMeetingUseCase(
            meetingRepository: meetingRepository,
            conversationRepository: conversationRepository
        )
        #if DEBUG
            if let failureID = UITestConfig.environment?.meetingsCreateFailureID {
                return MeetingsUITestCreateUseCase(wrapping: createUseCase, failureID: failureID)
            }
        #endif
        return createUseCase
    }

    private func makeFetchUpcomingMeetingsUseCase(
        meetingRepository: any MeetingRepositoryProtocol,
        currentDateProvider: any CurrentDateProviding
    ) -> any FetchUpcomingMeetingsUseCaseProtocol {
        let fetchUseCase = FetchUpcomingMeetingsUseCase(
            repository: meetingRepository,
            currentDateProvider: currentDateProvider
        )
        #if DEBUG
            if let failureID = UITestConfig.environment?.meetingsFailureID {
                return MeetingsUITestFetchUseCase(wrapping: fetchUseCase, failureID: failureID)
            }
        #endif
        return fetchUseCase
    }

}
