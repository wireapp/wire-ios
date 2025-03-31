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

package protocol SSOLoginVerificationTokenGeneratorProtocol: Sendable {

    func generateToken() -> SSOLoginVerificationToken

}

package struct SSOLoginVerificationTokenGenerator: SSOLoginVerificationTokenGeneratorProtocol {

<<<<<<< HEAD:WireAuthentication/Sources/WireAuthenticationAPI/Use cases/FetchSSOURLUseCaseProtocol.swift
    func fetchSSOURLUseCase(apiVersion: BackendMetadata.APIVersion) -> any FetchSSOURLUseCaseProtocol
=======
    package init() {}

    package func generateToken() -> SSOLoginVerificationToken {
        SSOLoginVerificationToken()
    }
>>>>>>> c679b9d42e (fix: cached SSO authentication - WPB-16767 (#2778)):WireAuthentication/Sources/WireAuthenticationLogic/Utilities/SSOLoginVerificationTokenGenerator.swift

}
