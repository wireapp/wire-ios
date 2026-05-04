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
import WireNetwork

// sourcery: AutoMockable
public protocol LoginViaEmailUseCaseProtocol: Sendable {

    func invoke(
        email: String,
        password: String,
        verificationCode: String?
    ) async throws -> ([HTTPCookie], AccessToken)

}

public enum LoginViaEmailUseCaseFailure: Error, Equatable {

    case invalidCredentials
    case twoFactorAuthenticationRequired
    case twoFactorAuthenticationFailed
    case accountPendingActivation
    case accountSuspended

}

public protocol LoginViaEmailUseCaseFactory {

    func loginViaEmailUseCase() async throws -> any LoginViaEmailUseCaseProtocol

}
