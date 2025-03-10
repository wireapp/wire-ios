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

package struct FetchSSOURLUseCase: FetchSSOURLUseCaseProtocol {

    private let authenticationAPI: any AuthenticationAPI
    private let linkGenerator: any SSOLinkGeneratorProtocol

    package init(
        authenticationAPI: any AuthenticationAPI,
        linkGenerator: any SSOLinkGeneratorProtocol
    ) {
        self.authenticationAPI = authenticationAPI
        self.linkGenerator = linkGenerator
    }

    package func invoke() async throws -> URL? {
        guard let ssoCode = try await authenticationAPI.getSSOCode() else {
            return nil
        }

        return try await linkGenerator.generateSSOLink(ssoCode: ssoCode)
    }

}

package struct FetchDefaultSSOSettingsUseCase: FetchDefaultSSOSettingsUseCaseProtocol {

    private let authenticationAPI: AuthenticationAPI

    package init(authenticationAPI: AuthenticationAPI) {
        self.authenticationAPI = authenticationAPI
    }

    package func invoke() async throws(FetchDefaultSSOSettingsUseCaseFailure) -> UUID? {
        do {
            return try await authenticationAPI.getSSOCode()
        } catch let error as URLError {
            switch error.code {
            case .notConnectedToInternet, .networkConnectionLost:
                throw .noInternet
            default:
                throw .unknown
            }
        } catch {
            throw .unknown
        }
    }

}
