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

/// A builder of `SelfUserAPI`.

public struct SelfUserAPIBuilder {

    let apiService: any APIServiceProtocol

    /// Create a new builder.
    ///
    /// - Parameter APIService: An api service.

    public init(apiService: any APIServiceProtocol) {
        self.apiService = apiService
    }

    /// Make a versioned `SelfUserAPI`.
    ///
    /// - Parameter version: An api version.
    /// - Returns: A versioned `SelfUserAPI`.

    public func makeAPI(for version: APIVersion) -> any SelfUserAPI {
        switch version {
        case .v0:
            SelfUserAPIV0(apiService: apiService)
        case .v1:
            SelfUserAPIV1(apiService: apiService)
        case .v2:
            SelfUserAPIV2(apiService: apiService)
        case .v3:
            SelfUserAPIV3(apiService: apiService)
        case .v4:
            SelfUserAPIV4(apiService: apiService)
        case .v5:
            SelfUserAPIV5(apiService: apiService)
        case .v6:
            SelfUserAPIV6(apiService: apiService)
        case .v7:
            SelfUserAPIV7(apiService: apiService)
        }
    }

}
