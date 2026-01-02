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
import WireAuthenticationAPI
import WireNetwork

public struct LoginViaEmailUseCase: LoginViaEmailUseCaseProtocol {

    private let authenticationAPI: AuthenticationAPI

    public init(authenticationAPI: AuthenticationAPI) {
        self.authenticationAPI = authenticationAPI
    }

    public func invoke(
        email: String,
        password: String,
        verificationCode: String?
    ) async throws -> ([HTTPCookie], AccessToken) {
        do {
            let (cookies, token) = try await authenticationAPI.login(
                email: email,
                password: password,
                verificationCode: verificationCode,
                label: nil
            )
            return (
                cookies,
                AccessToken(
                    userID: token.userID,
                    token: token.token,
                    type: token.type,
                    expirationDate: token.expirationDate
                )
            )
        } catch AuthenticationAPIError.twoFactorAuthenticationRequired {
            throw LoginViaEmailUseCaseFailure.twoFactorAuthenticationRequired
        } catch AuthenticationAPIError.twoFactorAuthenticationFailed {
            throw LoginViaEmailUseCaseFailure.twoFactorAuthenticationFailed
        } catch AuthenticationAPIError.accountPendingActivation {
            throw LoginViaEmailUseCaseFailure.accountPendingActivation
        } catch AuthenticationAPIError.accountSuspended {
            throw LoginViaEmailUseCaseFailure.accountSuspended
        } catch AuthenticationAPIError.invalidCredentials {
            throw LoginViaEmailUseCaseFailure.invalidCredentials
        }
    }

}
