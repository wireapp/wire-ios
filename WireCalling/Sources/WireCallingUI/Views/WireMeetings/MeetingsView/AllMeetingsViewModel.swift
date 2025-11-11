//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
package import SwiftUI
package import WireCallingDomain
import WireCallingDomainSupport
package import WireFoundation
package import WireReusableUIComponents

/// ViewModel responsible for the AllMeetingsView screen.
/// Owns the MeetingsViewModel for data logic and handles navigation actions.
package final class AllMeetingsViewModel: ObservableObject {

    package let meetingsViewModel: MeetingsViewModel

    @Published var isCreateInstantMeetingPresented: Bool = false
    @Published var isScheduleMeetingPresented: Bool = false

    public let accentColor: () -> Color
    private let passwordValidator: any PasswordValidator

    package init(
        repository: any MeetingsRepositoryProtocol,
        currentDateProvider: any CurrentDateProviding,
        formatter: MeetingsFormatter = MeetingsFormatter(),
        pastMeetingsUseCase: any FetchPastMeetingsUseCaseProtocol,
        upcomingMeetingsUseCase: any FetchUpcomingMeetingsUseCaseProtocol,
        accentColor: @escaping () -> Color,
        passwordValidator: any PasswordValidator
    ) {
        self.meetingsViewModel = MeetingsViewModel(
            repository: repository,
            currentDateProvider: currentDateProvider,
            formatter: formatter,
            pastMeetingsUseCase: pastMeetingsUseCase,
            upcomingMeetingsUseCase: upcomingMeetingsUseCase
        )
        self.accentColor = accentColor
        self.passwordValidator = passwordValidator
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
            accentColor: accentColor(),
            passwordValidator: passwordValidator
        )
    }

    func makeScheduleMeetingViewModel() -> ScheduleMeetingViewModel {
        ScheduleMeetingViewModel(accentColor: accentColor())
    }

}
