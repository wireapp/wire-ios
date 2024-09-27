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

/// A builder of `UpdateEventsAPI`.

public struct UpdateEventsAPIBuilder {
    // MARK: Lifecycle

    /// Create a new builder.
    ///
    /// - Parameter httpClient: A http client.

    public init(httpClient: any HTTPClient) {
        self.httpClient = httpClient
    }

    // MARK: Public

    /// Make a versioned `UpdateEventsAPI`.
    ///
    /// - Parameter version: An api version.
    /// - Returns: A versioned `UpdateEventsAPI`.

    public func makeAPI(for version: APIVersion) -> any UpdateEventsAPI {
        switch version {
        case .v0:
            UpdateEventsAPIV0(httpClient: httpClient)
        case .v1:
            UpdateEventsAPIV1(httpClient: httpClient)
        case .v2:
            UpdateEventsAPIV2(httpClient: httpClient)
        case .v3:
            UpdateEventsAPIV3(httpClient: httpClient)
        case .v4:
            UpdateEventsAPIV4(httpClient: httpClient)
        case .v5:
            UpdateEventsAPIV5(httpClient: httpClient)
        case .v6:
            UpdateEventsAPIV6(httpClient: httpClient)
        }
    }

    // MARK: Internal

    let httpClient: any HTTPClient
}
