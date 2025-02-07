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

public protocol AuthenticationAPI {

    /// Login via email
    ///
    /// - Parameters:
    ///   - email: Email address of the account
    ///   - password: Password
    ///   - verificationCode: The verification code is sent to the given user’s email address,
    ///   this is an optional field and depends on the team/server settings.
    ///   - label: An optional label to associate with the access token.
    /// - Returns: HTTP cookie, a valid access token.

    func login(
        email: String,
        password: String,
        verificationCode: String?,
        label: String?
    ) async throws -> ([HTTPCookie], AccessToken)

    /// Get on-prem config `URL` for domain

    func getOnPremConfigURL(forDomain domain: String) async throws -> DomainInfo

    /// Get domain registration configuration by email

    func getDomainRegistration(forEmail email: String) async throws -> DomainRegistrationConfiguration

}
