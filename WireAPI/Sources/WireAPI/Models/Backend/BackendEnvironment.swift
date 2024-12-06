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

/// A collection of data for connecting to a given backend environment (e.g. Production, Staging, etc).

public struct BackendEnvironment {

    /// The `URL` of the backend.

    let url: URL

    /// The `URL` of the WebSocket endpoint.

    let webSocketURL: URL

    /// The pinned keys for the backend for use with certificate pinning.

    let pinnedKeys: [PinnedKey]

    /// The proxy settings for the backend if any.

    let proxySettings: ProxySettings?

    /// Creates a new `BackendEnvironment`.
    ///
    /// - Parameter url: The `URL` of the backend.
    /// - Parameter webSocketURL: The `URL` of the WebSocket endpoint.
    /// - Parameter pinnedKeys: The pinned keys for the backend for use with certificate pinning.
    /// - Parameter proxySettings: The proxy settings for the backend if any.

    public init(url: URL, webSocketURL: URL, pinnedKeys: [PinnedKey], proxySettings: ProxySettings?) {
        self.url = url
        self.webSocketURL = webSocketURL
        self.pinnedKeys = pinnedKeys
        self.proxySettings = proxySettings
    }

}
