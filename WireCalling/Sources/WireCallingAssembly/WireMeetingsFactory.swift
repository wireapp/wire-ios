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
public import WireNetwork

import SwiftUI
import WireCallingData
import WireCallingUI
import WireFoundation

public struct WireMeetingsFactory {

    @MainActor
    public init() {}

    @MainActor
    public func makeMeetingsView(
        meetingsAPI: any MeetingsAPI,
        memberRepository: any MemberRepositoryProtocol,
        conversationRepository: any MeetingConversationRepositoryProtocol
    ) -> UIViewController {
        let meetingRepository = MeetingRepository.demo(meetingsAPI: meetingsAPI)
        let createInstantMeetingUseCase = CreateInstantMeetingUseCase(
            meetingRepository: meetingRepository,
            conversationRepository: conversationRepository,
            dateProvider: .system
        )
        let fetchUpcomingMeetingsUseCase = FetchUpcomingMeetingsUseCase(
            repository: meetingRepository,
            currentDateProvider: .system
        )
        let createScheduledMeetingUseCase = CreateScheduledMeetingUseCase(repository: meetingRepository)
        let meetingsViewModel = AllMeetingsViewModel(
            currentDateProvider: .system,
            upcomingMeetingsUseCase: fetchUpcomingMeetingsUseCase,
            memberRepository: memberRepository,
            createInstantMeetingUseCase: createInstantMeetingUseCase,
            createScheduledMeetingUseCase: createScheduledMeetingUseCase
        )
        return UIHostingController(rootView: AllMeetingsView(viewModel: meetingsViewModel))
    }

}
