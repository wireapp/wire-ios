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

/// A new environment coming from the authentication flow.

public struct NewEnvironment {

    /// The selected backend.

    public let backendEnvironment: BackendEnvironment2

    /// Recently resolved metadata.

    public let metadata: ResolvedBackendMetadata

    /// Cookies obtained from the authentication flow.

    public let cookies: [HTTPCookie]

    /// User submitted credentials for the backend proxy.

    public let proxyCredentials: WireNetwork.ProxyCredentials?

    /// Create a new `NewEnvironment`.

    public init(
        backendEnvironment: BackendEnvironment2,
        metadata: ResolvedBackendMetadata,
        cookies: [HTTPCookie],
        proxyCredentials: WireNetwork.ProxyCredentials?
    ) {
        self.backendEnvironment = backendEnvironment
        self.metadata = metadata
        self.cookies = cookies
        self.proxyCredentials = proxyCredentials
    }

}
