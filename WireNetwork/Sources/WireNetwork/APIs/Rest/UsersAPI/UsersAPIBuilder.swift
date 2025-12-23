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

/// A builder of `UsersAPI`.

public struct UsersAPIBuilder {

    let apiService: any APIServiceProtocol

    /// Create a new builder.
    ///
    /// - Parameter APIService: An api service.

    public init(apiService: any APIServiceProtocol) {
        self.apiService = apiService
    }

    /// Make a versioned `UsersAPI`.
    ///
    /// - Parameter version: An api version.
    /// - Returns: A versioned `UsersAPI`.

    public func makeAPI(for version: APIVersion) -> any UsersAPI {
        switch version {
        case .v0:
            UsersAPIV0(apiService: apiService)
        case .v1:
            UsersAPIV1(apiService: apiService)
        case .v2:
            UsersAPIV2(apiService: apiService)
        case .v3:
            UsersAPIV3(apiService: apiService)
        case .v4:
            UsersAPIV4(apiService: apiService)
        case .v5:
            UsersAPIV5(apiService: apiService)
        case .v6:
            UsersAPIV6(apiService: apiService)
        case .v7:
            UsersAPIV7(apiService: apiService)
        case .v8:
            UsersAPIV8(apiService: apiService)
        case .v9:
            UsersAPIV9(apiService: apiService)
        case .v10:
            UsersAPIV10(apiService: apiService)
        case .v11:
            UsersAPIV11(apiService: apiService)
        case .v12:
            UsersAPIV12(apiService: apiService)
        case .v13:
            UsersAPIV13(apiService: apiService)
        case .v14:
            UsersAPIV14(apiService: apiService)
        }
    }
}
