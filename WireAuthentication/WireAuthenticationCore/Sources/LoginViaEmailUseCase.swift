//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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
import WireAPI
import WireAuthenticationAPI

public struct LoginViaEmailUseCase: LoginViaEmailUseCaseProtocol {

    typealias Failure = LoginViaEmailUseCaseFailure

    let loginAPI: any LoginAPI
    // account manager
    // session manager

    public init(loginAPI: any LoginAPI) {
        self.loginAPI = loginAPI
    }

    public func invoke(
        email: String,
        password: String
    ) async throws (LoginViaEmailUseCaseFailure) {
        try validateCredentials(
            email: email,
            password: password
        )

        let (cookies, accessToken) = try await loginViaRemote(
            email: email,
            password: password
        )

        print("Got cookies: \(cookies.count)")
        // Create account new account in account manager
        // Store cookie for account
        // Create an authentecated session
    }

    private func validateCredentials(
        email: String,
        password: String
    ) throws (Failure) {
        guard
            !email.isEmpty,
            !password.isEmpty
        else {
            throw .invalidCredentials
        }
    }

    private func loginViaRemote(
        email: String,
        password: String
    ) async throws (Failure) -> ([HTTPCookie], AccessToken) {
        do {
            return try await loginAPI.login(
                email: email,
                password: password,
                twoFactorAuthenticationCode: nil
            )
        } catch LoginAPIError.invalidCredentials {
            throw .invalidCredentials
        } catch LoginAPIError.twoFactorAuthenticationRequired {
            throw .verificationCodeRequired
        } catch LoginAPIError.accountPendingActivation {
            throw .accountPendingActivation
        } catch LoginAPIError.accountSuspended {
            throw .accountSuspended
        } catch {
            throw .other(message: error.localizedDescription)
        }
    }

}
