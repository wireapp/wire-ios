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

/// The result of an authentication flow.

public struct AuthenticationResult: Equatable, Hashable, Sendable {

    /// The user id of whom the token belongs.

    public let userID: UUID

    /// The authentication cookies.

    public let cookies: [HTTPCookie]

    /// A token used to make authenticated requests to the backend if available.

    public let accessToken: AccessToken?

    /// The user's email credentials.

    public let emailCredentials: EmailCredentials?

    /// The connected backend.

    public let backendEnvironment: BackendEnvironment2

    /// The resolved backend metadata.

    public let backendMetadata: ResolvedBackendMetadata

    /// The user submitted proxy credentials.

    public let proxyCredentials: ProxyCredentials?

    public init(
        userID: UUID,
        cookies: [HTTPCookie],
        accessToken: AccessToken?,
        emailCredentials: EmailCredentials?,
        backendEnvironment: BackendEnvironment2,
        backendMetadata: ResolvedBackendMetadata,
        proxyCredentials: ProxyCredentials?
    ) {
        self.userID = userID
        self.cookies = cookies
        self.accessToken = accessToken
        self.emailCredentials = emailCredentials
        self.backendEnvironment = backendEnvironment
        self.backendMetadata = backendMetadata
        self.proxyCredentials = proxyCredentials
    }

}
