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

/// ViewModel responsible for the AllMeetingsView screen.
/// Owns the MeetingsViewModel for data logic and handles navigation actions.
@Observable
package final class AllMeetingsViewModel {

    let memberRepository: any MemberRepositoryProtocol

    package let meetingsViewModel: MeetingsViewModel

    var isCreateInstantMeetingPresented: Bool = false
    var isScheduleMeetingPresented: Bool = false

    package init(
        currentDateProvider: any CurrentDateProviding,
        formatter: MeetingsFormatter = MeetingsFormatter(),
        upcomingMeetingsUseCase: any FetchUpcomingMeetingsUseCaseProtocol,
        memberRepository: any MemberRepositoryProtocol
    ) {
        self.meetingsViewModel = MeetingsViewModel(
            currentDateProvider: currentDateProvider,
            formatter: formatter,
            upcomingMeetingsUseCase: upcomingMeetingsUseCase
        )
        self.memberRepository = memberRepository
    }

    // MARK: - Public Interface

    func createInstantMeetingTapped() {
        isCreateInstantMeetingPresented = true
    }

    func scheduleMeetingTapped() {
        isScheduleMeetingPresented = true
    }

    func makeCreateInstantMeetingViewModel() -> CreateInstantMeetingViewModel {
        CreateInstantMeetingViewModel(memberRepository: memberRepository)
    }

    func makeScheduleMeetingViewModel() -> ScheduleMeetingViewModel {
        ScheduleMeetingViewModel(memberRepository: memberRepository)
    }

}
