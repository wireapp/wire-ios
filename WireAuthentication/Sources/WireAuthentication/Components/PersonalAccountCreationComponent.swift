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
import NeedleFoundation
internal import WireAuthenticationUI
import WireAuthenticationAPI
internal import WireAuthenticationLogic

final class PersonalAccountCreationComponent: Component<PersonalAccountCreationComponentDependency> {

    private let email: String
    private let teamAccountCreationLink: URL?

    init(
        parent: any Scope,
        email: String,
        teamAccountCreationLink: URL?
    ) {
        self.email = email
        self.teamAccountCreationLink = teamAccountCreationLink
        super.init(parent: parent)
    }

    // MARK: - Children

    func verificationEmailCodeComponent(
        email: String,
        password: String,
        name: String
    ) -> VerificationEmailCodeComponent {
        VerificationEmailCodeComponent(
            parent: self,
            email: email,
            password: password,
            name: name
        )
    }

}

extension PersonalAccountCreationComponent: PersonalAccountCreationViewModel.Factory {

    // MARK: - Factory

    @MainActor var viewModel: PersonalAccountCreationViewModel {
        PersonalAccountCreationViewModel(
            factory: self,
            router: dependency.router,
            email: email,
            privacyPolicyURL: dependency.privacyPolicyURL,
            termsOfUseURL: dependency.termsOfUseURL,
            teamAccountCreationLink: teamAccountCreationLink,
            passwordValidator: dependency.passwordValidator
        )
    }

    func verificationEmailCodeFactory(
        email: String,
        password: String,
        name: String
    ) -> any VerificationEmailCodeFactory {
        verificationEmailCodeComponent(email: email, password: password, name: name)
    }

    // MARK: - Use cases

    func requestEmailVerificationCodeUseCase() async throws -> any RequestEmailVerificationCodeUseCaseProtocol {
        let authenticationAPI = try await dependency.networkStack.makeAuthenticationAPI()
        return RequestEmailVerificationCodeUseCase(authenticationAPI: authenticationAPI)
    }

    func validateEmailUseCase() -> any ValidateEmailUseCaseProtocol {
        ValidateEmailUseCase()
    }

    func registerPersonalAccountUseCase() async throws -> any RegisterPersonalAccountUseCaseProtocol {
        let authenticationAPI = try await dependency.networkStack.makeAuthenticationAPI()
        return RegisterPersonalAccountUseCase(authenticationAPI: authenticationAPI)
    }

}
