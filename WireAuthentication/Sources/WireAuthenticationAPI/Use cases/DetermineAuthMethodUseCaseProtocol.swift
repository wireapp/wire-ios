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

public protocol DetermineAuthMethodUseCaseProtocol: Sendable {

    @MainActor
    func invoke(emailOrSSOCode: String) async throws -> AuthenticationMethod

}

public enum AuthenticationMethod: Sendable, Hashable {

    /// Cloud login only

    case loginViaEmail(email: String, didDetectDomainConflict: Bool)

    ///  Cloud login or registration.

    case loginOrRegisterViaEmail(email: String)

    /// Cloud SSO login

    case loginViaSSO(code: UUID)

    /// On-prem login, either via email or SSO

    case onPremLogin(email: String?, backendConfig: URL)

}

public enum DetermineAuthMethodUseCaseFailure: Error, Equatable {

    /// The email or SSO code is invalid.

    case invalidEmailOrSSOCode

}

public protocol DetermineAuthMethodUseCaseFactory {

    func determineAuthMethodUseCase() async throws -> any DetermineAuthMethodUseCaseProtocol

}
