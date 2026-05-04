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

import Foundation
import WireAuthenticationAPI
import WireNetwork
import WireReusableUIComponents

struct FakePersonalAccountCreationFactory: PersonalAccountCreationFactory, RegisterPersonalAccountUseCaseFactory,
    RequestEmailVerificationCodeUseCaseFactory, ValidateEmailUseCaseFactory {

    var mockDependencies = MockDependencies()

    var email: String
    var environment: BackendEnvironment2
    var privacyPolicyURL: URL
    var termsOfUseURL: URL
    var teamAccountCreationLink: URL?
    var passwordValidator: PasswordValidator

    var viewModel: PersonalAccountCreationViewModel {
        .init(
            factory: self,
            router: FakeRootFactory().viewModel,
            email: email,
            environment: environment,
            privacyPolicyURL: privacyPolicyURL,
            termsOfUseURL: termsOfUseURL,
            teamAccountCreationLink: teamAccountCreationLink,
            passwordValidator: passwordValidator,
            analyticsEventTracker: mockDependencies.analyticsEventTracker
        )
    }

    func verificationEmailCodeFactory(
        email: String,
        password: String,
        name: String,
        trackingConsent: RegistrationAnalyticsTrackingConsent
    ) -> any VerificationEmailCodeFactory {
        fatalError()
    }

    func registerPersonalAccountUseCase() async throws -> any RegisterPersonalAccountUseCaseProtocol {
        try await mockDependencies.registerPersonalAccountUseCase()
    }

    func requestEmailVerificationCodeUseCase() async throws -> any RequestEmailVerificationCodeUseCaseProtocol {
        await mockDependencies.requestEmailVerificationCodeUseCase()
    }

    func validateEmailUseCase() -> any ValidateEmailUseCaseProtocol {
        mockDependencies.validateEmailUseCase()
    }

}
