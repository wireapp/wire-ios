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

package struct RegisterPersonalAccountUseCase: RegisterPersonalAccountUseCaseProtocol {

    private let authenticationAPI: AuthenticationAPI

    package init(authenticationAPI: AuthenticationAPI) {
        self.authenticationAPI = authenticationAPI
    }

    package func invoke(
        email: String,
        password: String,
        verificationCode: String,
        name: String
    ) async throws -> ([HTTPCookie], UUID?) {
        do {
            return try await authenticationAPI.registerAccount(
                email: email,
                emailCode: verificationCode,
                name: name,
                password: password,
                label: UUID().uuidString
            )
        } catch AuthenticationAPIError.RegistrationError.invalidEmail {
            throw RegisterPersonalAccountUseCaseError.invalidEmail
        } catch AuthenticationAPIError.RegistrationError.blacklistedEmail {
            throw RegisterPersonalAccountUseCaseError.blacklistedEmail
        } catch AuthenticationAPIError.RegistrationError.tooManyTeamMembers {
            throw RegisterPersonalAccountUseCaseError.tooManyTeamMembers
        } catch AuthenticationAPIError.RegistrationError.userCreationRestricted {
            throw RegisterPersonalAccountUseCaseError.userCreationRestricted
        } catch AuthenticationAPIError.RegistrationError.invalidCode {
            throw RegisterPersonalAccountUseCaseError.invalidCode
        } catch AuthenticationAPIError.RegistrationError.keyExists {
            throw RegisterPersonalAccountUseCaseError.emailExists
        }
    }

}
