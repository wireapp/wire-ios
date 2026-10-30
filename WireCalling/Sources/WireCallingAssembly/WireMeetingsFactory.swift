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
import WireDesign
import WireFoundation

public struct WireMeetingsFactory {

    private let selfUserID: UUID
    private let supportsMeetingLinks: Bool
    private let isClipboardEnabled: Bool

    @MainActor
    public init(selfUserID: UUID, supportsMeetingLinks: Bool = false, isClipboardEnabled: Bool = true) {
        self.selfUserID = selfUserID
        self.supportsMeetingLinks = supportsMeetingLinks
        self.isClipboardEnabled = isClipboardEnabled
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
        let updateMeetingUseCase = makeUpdateMeetingUseCase(
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
        let fetchMeetingLink: @Sendable (QualifiedID) async throws -> MeetingLink? = {
            try await meetingRepository.fetchMeetingLink(id: $0)
        }
        let refreshMeetingLink: @Sendable (QualifiedID, String?) async throws -> MeetingLink? = {
            try await meetingRepository.refreshMeetingLink(id: $0, password: $1)
        }
        let meetingsViewModel = AllMeetingsViewModel(
            currentDateProvider: currentDateProvider,
            upcomingMeetingsUseCase: fetchUpcomingMeetingsUseCase,
            observeMeetingChangesUseCase: observeMeetingChangesUseCase,
            deleteMeetingUseCase: deleteMeetingUseCase,
            selfUserID: selfUserID,
            observeAttendedMeetingsUseCase: observeAttendedMeetingsUseCase,
            joinMeetingCallUseCase: joinMeetingCallUseCase,
            fetchMeetingLink: supportsMeetingLinks ? fetchMeetingLink : nil,
            refreshMeetingLink: supportsMeetingLinks ? refreshMeetingLink : nil,
            makeFormViewModel: { mode, onSuccess in
                MeetingFormViewModel(
                    mode: mode,
                    searchMembersUseCase: searchMembersUseCase,
                    createMeetingUseCase: createMeetingUseCase,
                    updateMeetingUseCase: updateMeetingUseCase,
                    currentDateProvider: currentDateProvider,
                    supportsMeetingLinks: supportsMeetingLinks,
                    fetchMeetingLink: supportsMeetingLinks ? fetchMeetingLink : nil,
                    refreshMeetingLink: supportsMeetingLinks ? refreshMeetingLink : nil,
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
                .environment(\.isClipboardEnabled, isClipboardEnabled)
                .environment(\.supportsMeetingEmailInvitations, supportsMeetingLinks)
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

    private func makeUpdateMeetingUseCase(
        meetingRepository: any MeetingRepositoryProtocol,
        conversationRepository: any MeetingConversationRepositoryProtocol
    ) -> any UpdateMeetingUseCaseProtocol {
        let updateUseCase = UpdateMeetingUseCase(
            meetingRepository: meetingRepository,
            conversationRepository: conversationRepository
        )
        #if DEBUG
            if let failureID = UITestConfig.environment?.meetingsUpdateFailureID {
                return MeetingsUITestUpdateUseCase(wrapping: updateUseCase, failureID: failureID)
            }
        #endif
        return updateUseCase
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
