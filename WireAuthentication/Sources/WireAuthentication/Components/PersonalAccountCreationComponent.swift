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

import NeedleFoundation
internal import WireAuthenticationUI
import WireAuthenticationDomain
internal import WireAuthenticationData

final class PersonalAccountCreationComponent: Component<PersonalAccountCreationComponentDependency> {

    private let email: String

    init(
        parent: any Scope,
        email: String
    ) {
        self.email = email
        super.init(parent: parent)
    }

    // MARK: - Children

}

extension PersonalAccountCreationComponent: PersonalAccountCreationFactory {

    // MARK: - Factory

    @MainActor var viewModel: PersonalAccountCreationViewModel {
        PersonalAccountCreationViewModel()
    }

    // MARK: - Use cases

    func requestEmailVerificationCodeUseCase() async throws -> any RequestEmailVerificationCodeUseCaseProtocol {
        let authenticationAPI = try await dependency.networkStack.makeAuthenticationAPI()
        return RequestEmailVerificationCodeUseCase(authenticationAPI: authenticationAPI)
    }

}

//import WireAPI
//import WireTransport
//
//final class AuthenticationAPIRepositoryAdapter: AuthenticationAPIRepository {
//
//    private let api: AuthenticationAPI
//
//    init(api: AuthenticationAPI) {
//        self.api = api
//    }
//
//    func login(
//        email: String,
//        password: String,
//        verificationCode: String?,
//        label: String?
//    ) async throws -> ([HTTPCookie], WireAuthenticationDomain.AccessToken) {
//        let (cookies, accessToken) = try await api.login(
//            email: email,
//            password: password,
//            verificationCode: verificationCode,
//            label: label
//        )
//        return (cookies, WireAuthenticationDomain
//                .AccessToken(
//                    userID: accessToken.userID,
//                    token: accessToken.token,
//                    type: accessToken.type,
//                    expirationDate: accessToken.expirationDate
//                ))
//    }
//
//    func getOnPremConfigURL(forDomain domain: String) async throws -> DomainInfo {
//        try await api.getOnPremConfigURL(forDomain: domain)
//    }
//
//    func getDomainRegistration(forEmail email: String) async throws -> DomainRegistrationConfiguration {
//        try await api.getDomainRegistration(forEmail: email)
//    }
//
//    func validateLoginToken(ssoCode: UUID) async throws {
//        try await api.validateLoginToken(ssoCode: ssoCode)
//    }
//
//    func getSSOCode() async throws -> UUID? {
//        try await api.getSSOCode()
//    }
//
//    func requestVerificationCode(for email: String) async throws {
//        try await api.requestVerificationCode(for: email)
//    }
//
//    func requestEmailVerificationCode(for email: String) async throws {
//        try await api.requestEmailVerificationCode(for: email)
//    }
//
//    func registerAccount(
//        email: String,
//        emailCode: String,
//        name: String,
//        password: String
//    ) async throws {
//        try await api.registerAccount(
//            email: email,
//            emailCode: emailCode,
//            name: name,
//            password: password
//        )
//    }
//}
