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

/// Information about a connected backend.

public struct BackendMetadata: Sendable, Equatable, Hashable {

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

    // TODO: [WPB-16272] Remove duplication
    public enum APIVersion: Sendable, Equatable, Hashable {

        case v0
        case v1
        case v2
        case v3
        case v4
        case v5
        case v6
        case v7
        case v8

    }

}
