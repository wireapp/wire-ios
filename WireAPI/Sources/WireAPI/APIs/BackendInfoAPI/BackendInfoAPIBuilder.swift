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

/// A builder of `BackendInfoAPI`.

public struct BackendInfoAPIBuilder {

    let apiService: any APIServiceProtocol

    /// Create a new builder.
    ///
    /// - Parameter apiService: A service for executing requests.`

    public init(apiService: any APIServiceProtocol) {
        self.apiService = apiService
    }

    /// Make a `BackendInfoAPI`.
    ///
    /// - Parameter version: An api version.
    /// - Returns: A `BackendInfoAPI`.

    public func makeAPI(for version: APIVersion) -> any BackendInfoAPI {
        switch version {
        case .v0:
            BackendInfoAPIV0(apiService: apiService)
        case .v1:
            BackendInfoAPIV1(apiService: apiService)
        case .v2:
            BackendInfoAPIV2(apiService: apiService)
        case .v3:
            BackendInfoAPIV3(apiService: apiService)
        case .v4:
            BackendInfoAPIV4(apiService: apiService)
        case .v5:
            BackendInfoAPIV5(apiService: apiService)
        case .v6:
            BackendInfoAPIV6(apiService: apiService)
        case .v7:
            BackendInfoAPIV7(apiService: apiService)
        }
    }

}
