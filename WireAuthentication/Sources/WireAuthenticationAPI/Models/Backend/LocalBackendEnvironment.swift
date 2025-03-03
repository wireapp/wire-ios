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

// TODO: [WPB-16272] Remove duplication
public struct LocalBackendEnvironment {

    /// The backend's title.

    public let title: String

    /// The backend's domain which describes the namespace
    /// for objects beloging to this backend.

    public let domain: String

    /// The resolved api version to use when communicating
    /// with this backend.

    public let resolvedAPIVersion: Int

    /// Whether this backend is allowed to communicated with
    /// other backends.

    public let isFederationEnabled: Bool

    /// Whether this backend supports the MLS communcation protocol.

    public let isMLSEnabled: Bool

    /// The base endpoints available on this backend.

    public let endpoints: Endpoints

    /// The backends certificate pinning keys.

    public let pinnedKeys: [Data]

    /// The proxy configuration.
    ///
    /// If present, then all requests must be proxied.

    public let proxySettings: LocalProxySettings?

    public init(
        title: String,
        domain: String,
        resolvedAPIVersion: Int,
        isFederationEnabled: Bool,
        isMLSEnabled: Bool,
        endpoints: Endpoints,
        pinnedKeys: [Data],
        proxySettings: LocalProxySettings?
    ) {
        self.title = title
        self.domain = domain
        self.resolvedAPIVersion = resolvedAPIVersion
        self.isFederationEnabled = isFederationEnabled
        self.isMLSEnabled = isMLSEnabled
        self.endpoints = endpoints
        self.pinnedKeys = pinnedKeys
        self.proxySettings = proxySettings
    }

    /// Endpoints available on a backend.

    public struct Endpoints {

        /// The base url for requests to the REST api.

        public let restAPIURL: URL

        /// The base url for requests to establish a websocket.

        public let websocketURL: URL

        /// The url to the "accounts" endpoint.

        public let accountsURL: URL

        public init(
            restAPIURL: URL,
            websocketURL: URL,
            accountsURL: URL
        ) {
            self.restAPIURL = restAPIURL
            self.websocketURL = websocketURL
            self.accountsURL = accountsURL
        }

    }

}
