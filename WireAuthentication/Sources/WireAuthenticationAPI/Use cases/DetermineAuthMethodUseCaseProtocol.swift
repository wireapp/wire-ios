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

public protocol DetermineAuthMethodUseCaseProtocol {

    @MainActor
    func invoke(emailOrSSOCode: String) async throws(DetermineAuthMethodUseCaseFailure) -> AuthenticationMethod

}

public enum AuthenticationMethod: Sendable, Hashable {

    /// Cloud login only

    case loginViaEmail(email: String)

    ///  Cloud login or registration.

    case loginOrRegisterViaEmail(email: String)

    /// Cloud SSO login

    case loginViaSSO(code: UUID)

    /// On-prem login, either via email or SSO

    case onPremLogin(email: String, backendConfig: URL)

}

public enum DetermineAuthMethodUseCaseFailure: Error, Equatable {

    case invalidEmailOrSSOCode

    /// The email domain has been claimed by an on-prem backend but there's already an existing cloud account registered
    /// - note: To proceed, alert the use then continue to login using the `recovery` method.

    case onPremNotPossible(recovery: AuthenticationMethod)

    /// Indicates that the domain registration response was invalid.

    case invalidResponse

    ///

    case cloudAccountAlreadyRegistered

    case urlError(URLError)

    case unknown
}
