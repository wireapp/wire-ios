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
import SwiftUI
import WireCallingDomain
import WireReusableUIComponents

final class ScheduleMeetingViewModel: ObservableObject {

    @Published var meetingTitle: String = ""

    // TODO: [WPB-21335] Implement Wire users and emails
    @Published var participants: String = ""
    @Published var allowGuests: Bool = false
    @Published var password: String = ""
    @Published var confirmedPassword: String = ""
    @Published var startDate: Date = .init()
    @Published var endDate: Date = .init().addingTimeInterval(1800)
    @Published var repeatOption: RepeatOption = .never

    var isNextButtonEnabled: Bool {
        let hasValidTitle = !meetingTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasValidPassword = password.isEmpty || (isPasswordValid && isConfirmedPasswordValid)
        return hasValidTitle && hasValidPassword
    }

    var isPasswordValid: Bool {
        password.isEmpty || passwordValidator.isPasswordValid(password)
    }

    var isConfirmedPasswordValid: Bool {
        confirmedPassword.isEmpty || password == confirmedPassword
    }

    var localizedPasswordRules: String {
        passwordValidator.localizedRulesDescription ?? ""
    }

    private let passwordValidator: any PasswordValidator
    private(set) var isContextMenuAllowed: Bool

    // MARK: - Initialization

    init(passwordValidator: any PasswordValidator, isContextMenuAllowed: Bool) {
        self.passwordValidator = passwordValidator
        self.isContextMenuAllowed = isContextMenuAllowed
    }

    // MARK: - Public Interface

    func scheduleMeeting() {}

}

extension RepeatOption {

    typealias Strings = L10n.Localizable.WireMeetings.Schedule.Time

    var title: String {
        switch self {
        case .never:
            Strings.never
        case .daily:
            Strings.daily
        case .weekly:
            Strings.weekly
        case .every2Weeks:
            Strings.everyTwoWeeks
        case .monthly:
            Strings.monthly
        case .yearly:
            Strings.yearly
        }
    }

}
