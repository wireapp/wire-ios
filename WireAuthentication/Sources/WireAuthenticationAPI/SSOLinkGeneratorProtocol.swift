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

// sourcery: AutoMockable
/// A protocol responsible for generating the Single Sign-On (SSO) authentication link.
public protocol SSOLinkGeneratorProtocol: Sendable {

    /// Generates the URL for the SSO authentication screen.
    ///
    /// - Parameters:
    ///   - ssoCode: SSO code.
    /// - Returns: URL to the SSO authentication screen.

    func generateSSOLink(ssoCode: UUID) async throws -> URL

    /// Flushes the temporary SSO login token stored in the user defaults.

    func flushToken()

}

public protocol SSOLinkGeneratorFactory {

    func ssoLinkGenerator() async throws -> any SSOLinkGeneratorProtocol

}

public enum SSOLinkGeneratorFailure: Error {

    /// The SSO code is invalid.

    case invalidSSOCode

    /// The SSO URL is invalid.

    case invalidSSOURL

}
