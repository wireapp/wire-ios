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
import WireReusableUIComponents

@MainActor
package final class PersonalAccountCreationViewModel: ObservableObject {

    package typealias Factory =
        RequestEmailVerificationCodeUseCaseFactory &
        RegisterPersonalAccountUseCaseFactory &
        ValidateEmailUseCaseFactory &
        PersonalAccountCreationFactory


    @Published var alert: Alert?
    @Published var isCreateTeamAccountPresented = false
    @Published var dataUsageAgreementAccepted: Bool = false
    @Published var name: String = ""
    @Published var email: String
    @Published var password: String = ""
    @Published var confirmedPassword: String = ""

    // MARK: - Dependencies

    var localizedPasswordRules: String {
        passwordValidator.localizedRulesDescription ?? ""
    }

    package let factory: any Factory
    private let router: any Router
    package let privacyPolicyURL: URL
    package let termsOfUseURL: URL
    private let passwordValidator: any PasswordValidator

    package init(
        factory: any Factory,
        router: any Router,
        email: String,
        privacyPolicyURL: URL,
        termsOfUseURL: URL,
        passwordValidator: any PasswordValidator
    ) {
        self.factory = factory
        self.router = router
        self.email = email
        self.privacyPolicyURL = privacyPolicyURL
        self.termsOfUseURL = termsOfUseURL
        self.passwordValidator = passwordValidator
    }

    // MARK: - Validations

    func isPasswordValid(_ password: String) -> Bool {
        passwordValidator.isPasswordValid(password)
    }

    var isEmailValid: Bool {
        factory.validateEmailUseCase().invoke(email: email) == .isValid
    }

    var isNameValid: Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count > 2 && trimmed.count < 64
    }

    var isPasswordValid: Bool {
        passwordValidator.isPasswordValid(password)
    }

    var isPasswordMatchConfirmedPassword: Bool {
        password == confirmedPassword
    }

    var canRequestVerificationCode: Bool {
        isNameValid && isEmailValid && isPasswordValid && isPasswordMatchConfirmedPassword
    }

    func requestEmailVerificationCode() async throws {
//        guard canRequestVerificationCode else {
//            return
//        }
//        let requestEmailVerificationCode = try await factory.requestEmailVerificationCodeUseCase()
//        try await requestEmailVerificationCode.invoke(email: email)

        router.navigate(to: PersonalAccountCreationDestination.verifyEmail(
            email: email,
            password: password,
            name: name
        ))
    }

}
