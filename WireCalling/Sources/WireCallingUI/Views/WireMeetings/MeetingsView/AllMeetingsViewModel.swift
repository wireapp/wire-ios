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
package import WireReusableUIComponents

import Combine
import SwiftUI
import WireCallingDomainSupport

/// ViewModel responsible for the AllMeetingsView screen.
/// Owns the MeetingsViewModel for data logic and handles navigation actions.
package final class AllMeetingsViewModel: ObservableObject {

    package let meetingsViewModel: MeetingsViewModel

    @Published var isCreateInstantMeetingPresented: Bool = false
    @Published var isScheduleMeetingPresented: Bool = false

    private let passwordValidator: any PasswordValidator
    private let isContextMenuAllowed: Bool

    package init(
        currentDateProvider: any CurrentDateProviding,
        formatter: MeetingsFormatter = MeetingsFormatter(),
        upcomingMeetingsUseCase: any FetchUpcomingMeetingsUseCaseProtocol,
        passwordValidator: any PasswordValidator,
        isContextMenuAllowed: Bool
    ) {
        self.meetingsViewModel = MeetingsViewModel(
            currentDateProvider: currentDateProvider,
            formatter: formatter,
            upcomingMeetingsUseCase: upcomingMeetingsUseCase
        )
        self.passwordValidator = passwordValidator
        self.isContextMenuAllowed = isContextMenuAllowed
    }

    // MARK: - Public Interface

    func createInstantMeetingTapped() {
        isCreateInstantMeetingPresented = true
    }

    func scheduleMeetingTapped() {
        isScheduleMeetingPresented = true
    }

    func makeCreateInstantMeetingViewModel() -> CreateInstantMeetingViewModel {
        CreateInstantMeetingViewModel(
            passwordValidator: passwordValidator,
            isContextMenuAllowed: isContextMenuAllowed
        )
    }

    func makeScheduleMeetingViewModel() -> ScheduleMeetingViewModel {
        ScheduleMeetingViewModel(
            passwordValidator: passwordValidator,
            isContextMenuAllowed: isContextMenuAllowed
        )
    }

}
