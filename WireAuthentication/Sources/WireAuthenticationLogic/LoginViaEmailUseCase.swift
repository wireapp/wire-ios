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
import WireAPI
import WireAuthenticationAPI

public struct LoginViaEmailUseCase: LoginViaEmailUseCaseProtocol {

    private let authenticationAPI: AuthenticationAPI

    public init(authenticationAPI: AuthenticationAPI) {
        self.authenticationAPI = authenticationAPI
    }

    public func invoke(
        email: String,
        password: String,
        verificationCode: String?
    ) async throws(LoginViaEmailUseCaseFailure)  -> ([HTTPCookie], AccessToken) {
        do {
            return try await authenticationAPI.login(
                email: email,
                password: password,
                verificationCode: verificationCode,
                label: nil
            )
        } catch let error as AuthenticationAPIError {
            switch error {
            case .twoFactorAuthenticationRequired:
                throw .twoFactorAuthenticationRequired
            case .twoFactorAuthenticationFailed:
                throw .twoFactorAuthenticationFailed
            case .accountPendingActivation:
                throw .accountPendingActivation
            case .accountSuspended:
                throw .accountSuspended
            case .invalidCredentials:
                throw .invalidCredentials
            default:
                throw .other
            }
        } catch let error as URLError {
            switch error.code {
            case .notConnectedToInternet, .networkConnectionLost:
                throw .noInternet
            default:
                throw .other
            }
        } catch {
            throw .other
        }
    }

}
