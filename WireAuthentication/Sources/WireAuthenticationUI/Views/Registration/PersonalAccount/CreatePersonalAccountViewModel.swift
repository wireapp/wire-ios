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

import SwiftUI
import WireAuthenticationAPI
import WireAuthenticationLogic

@MainActor
package final class CreatePersonalAccountViewModel: ObservableObject {

    @Published var isCreateTeamAccountPresented = false
    @Published var dataUsageAgreementAccepted: Bool = false
    @Published var name: String = ""
    @Published var email: String
    @Published var password: String = ""
    @Published var confirmedPassword: String = ""

    let privacyPolicyURL: URL
    // TODO: should it be optional?
    let teamAccountCreationLink: URL?
    let validateEmailUseCase: any ValidateEmailUseCaseProtocol 

    init(
        email: String,
        privacyPolicyURL: URL,
        teamAccountCreationLink: URL?,
        validateEmailUseCase: any ValidateEmailUseCaseProtocol =  ValidateEmailUseCase()
    ) {
        self.email = email
        self.privacyPolicyURL = privacyPolicyURL
        self.teamAccountCreationLink = teamAccountCreationLink
        self.validateEmailUseCase = validateEmailUseCase
    }

    // MARK: - Validations

    func isPasswordValid(_ password: String) -> Bool {
        // TODO:
        return true
    }

    var isEmailValid: Bool {
        validateEmailUseCase.invoke(email: email) == .isValid
    }

    var isNameValid: Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count > 2 && trimmed.count < 64
    }

    var isPasswordValid: Bool {
        // TODO:
        return true
    }

    var isPasswordMatchConfirmedPassword: Bool {
        password == confirmedPassword
    }

    var canSubmitCredentials: Bool {
        isNameValid && isEmailValid && isPasswordValid && isPasswordMatchConfirmedPassword
    }

    func submitCredentials() async {
        guard canSubmitCredentials else {
            return
        }
        // TODO: send to the next screen
    }

}
