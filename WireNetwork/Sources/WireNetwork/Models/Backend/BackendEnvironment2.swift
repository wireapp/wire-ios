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

// TODO: [WPB-12140] rename to BackendEnvironment

/// A collection of data for connecting to a given backend environment
/// (e.g. Production, Staging, etc).

public struct BackendEnvironment2: Sendable, Equatable, Hashable {

    /// The  name of the backend.

    public let title: String

    /// The type of backend environment.

    public let environmentType: EnvironmentType

    /// Information regarding how to connect to the backend.

    public let config: Config

    /// Create a new `BackendEnvironment`.
    ///
    /// - Parameters:
    ///   - title: The name of the backend.
    ///   - environmentType: The type of backend environment.
    ///   - config: Information regarding how to connect to the backend.

    public init(
        title: String,
        environmentType: EnvironmentType,
        config: Config,
    ) {
        self.title = title
        self.environmentType = environmentType
        self.config = config
    }

    // TODO: [WPB-12140] delete when no longer needed.
    public enum EnvironmentType: Sendable, Equatable, Hashable {

        case `default`
        case staging
        case anta
        case bella
        case chala
        case diya
        case elna
        case foma
        case custom(url: URL)

    }

    /// Configuration data for the environment.

    public struct Config: Sendable, Equatable, Hashable {

        /// The endpoints exposed by the backend.

        public let endpoints: Endpoints

        /// Configuration for certificate pinning.

        public let pinnedKeys: [PinnedKey]

        /// Configuration for proxy mode.

        public let proxyConfig: ProxyConfig?

        public init(
            endpoints: Endpoints,
            pinnedKeys: [PinnedKey],
            proxyConfig: ProxyConfig?
        ) {
            self.endpoints = endpoints
            self.pinnedKeys = pinnedKeys
            self.proxyConfig = proxyConfig
        }

    }

    /// Endpoints exposed by the backend.

    public struct Endpoints: Sendable, Equatable, Hashable {

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

        public init(
            restAPIURL: URL,
            websocketURL: URL,
            blacklistURL: URL,
            teamsURL: URL,
            accountsURL: URL,
            websiteURL: URL,
            countlyURL: URL?
        ) {
            self.restAPIURL = restAPIURL
            self.websocketURL = websocketURL
            self.blacklistURL = blacklistURL
            self.teamsURL = teamsURL
            self.accountsURL = accountsURL
            self.websiteURL = websiteURL
            self.countlyURL = countlyURL
        }

    }

    /// Configuration for proxy mode.

    public struct ProxyConfig: Sendable, Equatable, Hashable {

        /// The proxy host.

        public let host: String

        /// The proxy port.

        public let port: Int

        /// Whether proxy credentials are required.

        public let needsAuthentication: Bool

        /// Create a new `ProxyConfig`.

        public init(
            host: String,
            port: Int,
            needsAuthentication: Bool = false
        ) {
            self.host = host
            self.port = port
            self.needsAuthentication = needsAuthentication

        }

    }

}

public extension BackendEnvironment2 {

    var isCloudEnvironment: Bool {
        config.endpoints.restAPIURL.host() == "prod-nginz-https.wire.com"
    }

    static func isCloudDomain(_ domain: String) -> Bool {
        domain == "wire.com"
    }

    var isStagingEnvironment: Bool {
        config.endpoints.restAPIURL.host() == "staging-nginz-https.zinfra.io"
    }

    static func isStagingDomain(_ domain: String) -> Bool {
        domain == "staging.zinfra.io"
    }

}
