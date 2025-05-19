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

// TODO: rename to BackendEnvironment

/// A collection of data for connecting to a given backend environment
/// (e.g. Production, Staging, etc).

public struct BackendEnvironment2: Sendable {

    /// The  name of the backend.

    public let title: String

    /// The endpoints exposed by the backend.

    public let endpoints: Endpoints

    /// The pinned keys for the backend for use with certificate pinning.

    public let pinnedKeys: [PinnedKey]

    /// The proxy settings for the backend if any.

    public let proxySettings: ProxySettings?

    /// Information about the connected backend.

    public let metadata: ResolvedBackendMetadata

    /// Create a new `BackendEnvironment`.
    ///
    /// - Parameters:
    ///   - title: The name of the backend.
    ///   - endpoints: The endpoints exposed by the backend.
    ///   - pinnedKeys: Keys for use with certificate pinning.
    ///   - proxySettings: Settings to connect via a proxy.
    ///   - metadata: Information about the connected backend.

    public init(
        title: String,
        endpoints: Endpoints,
        url: URL,
        webSocketURL: URL,
        pinnedKeys: [PinnedKey],
        proxySettings: ProxySettings?,
        metadata: ResolvedBackendMetadata
    ) {
        self.title = title
        self.endpoints = endpoints
        self.pinnedKeys = pinnedKeys
        self.proxySettings = proxySettings
        self.metadata = metadata
    }

    /// Endpoints exposed by the backend.

    public struct Endpoints: Sendable {

        /// URL for the REST API.

        public let restAPIURL: URL

        /// URL for the websocket.

        public let websocketURL: URL

        /// URL for fetching the version blacklist.

        public let blacklistURL: URL

        /// URL for team management pages.

        public let teamsURL: URL

        /// URL for account management pages.

        public let accountsURL: URL

        /// URL for the app website.

        public let websiteURL: URL

        /// URL for the Countly analytics server.

        public let countlyURL: URL?

    }

    /// Information about a connected backend.

    public struct ResolvedBackendMetadata: Sendable {

        /// The REST API version to use when making requests.

        public let apiVersion: APIVersion

        /// The backend's domain.

        public let domain: String

        /// Whether this backend can communicate with other backends.

        public let isFederationEnabled: Bool

        public init(
            apiVersion: APIVersion,
            domain: String,
            isFederationEnabled: Bool
        ) {
            self.apiVersion = apiVersion
            self.domain = domain
            self.isFederationEnabled = isFederationEnabled
        }

    }

}
