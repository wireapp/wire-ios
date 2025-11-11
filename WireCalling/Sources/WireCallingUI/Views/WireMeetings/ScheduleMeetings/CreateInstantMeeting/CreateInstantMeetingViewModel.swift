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
import WireReusableUIComponents

final class CreateInstantMeetingViewModel: ObservableObject {

    @Published var meetingTitle: String = "" {
        didSet { updateNextButtonState() }
    }
    // TODO: [WPB-21335] Implement Wire users and emails
    @Published var participants: String = ""
    @Published var allowGuests: Bool = false
    @Published var password: String = "" {
        didSet { updateNextButtonState() }
    }
    @Published var confirmedPassword: String = "" {
        didSet { updateNextButtonState() }
    }

    @Published private(set) var isNextButtonEnabled: Bool = false

    var isPasswordValid: Bool {
        password.isEmpty || passwordValidator.isPasswordValid(password)
    }

    var isConfirmedPasswordValid: Bool {
        confirmedPassword.isEmpty || password == confirmedPassword
    }

    var localizedPasswordRules: String {
        passwordValidator.localizedRulesDescription ?? ""
    }

    let accentColor: Color
    private let passwordValidator: any PasswordValidator

    // MARK: - Initialization

    init(accentColor: Color, passwordValidator: any PasswordValidator) {
        self.accentColor = accentColor
        self.passwordValidator = passwordValidator
        updateNextButtonState()
    }

    // MARK: - Private Methods

    private func updateNextButtonState() {
        let hasValidTitle = !meetingTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasValidPassword = password.isEmpty || (isPasswordValid && isConfirmedPasswordValid)
        isNextButtonEnabled = hasValidTitle && hasValidPassword
    }

    // MARK: - Public Interface

    func createInstantMeeting() {}

}
