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

/// A builder of `TeamsAPI`.

public struct TeamsAPIBuilder {

    let apiService: any APIServiceProtocol

    /// Create a new builder.
    ///
    /// - Parameter APIService: An api service.

    public init(apiService: any APIServiceProtocol) {
        self.apiService = apiService
    }

    /// Make a versioned`TeamsAPI`.
    ///
    /// - Parameter version: An api version.
    /// - Returns: A versioned `TeamsAPI`.

    public func makeAPI(for version: APIVersion) -> any TeamsAPI {
        switch version {
        case .v0:
            TeamsAPIV0(apiService: apiService)
        case .v1:
            TeamsAPIV1(apiService: apiService)
        case .v2:
            TeamsAPIV2(apiService: apiService)
        case .v3:
            TeamsAPIV3(apiService: apiService)
        case .v4:
            TeamsAPIV4(apiService: apiService)
        case .v5:
            TeamsAPIV5(apiService: apiService)
        case .v6:
            TeamsAPIV6(apiService: apiService)
        case .v7:
            TeamsAPIV7(apiService: apiService)
        case .v8:
            TeamsAPIV8(apiService: apiService)
        case .v9:
            TeamsAPIV9(apiService: apiService)
        case .v10:
            TeamsAPIV10(apiService: apiService)
        case .v11:
            TeamsAPIV11(apiService: apiService)
        case .v12:
            TeamsAPIV12(apiService: apiService)
        case .v13:
            TeamsAPIV13(apiService: apiService)
        }
    }
}
