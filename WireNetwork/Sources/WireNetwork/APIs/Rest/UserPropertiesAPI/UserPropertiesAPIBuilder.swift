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

/// A builder of `UserPropertiesAPI`.

public struct UserPropertiesAPIBuilder {

    let apiService: any APIServiceProtocol

    /// Create a new builder.
    ///
    /// - Parameter APIService: An api service.

    public init(apiService: any APIServiceProtocol) {
        self.apiService = apiService
    }

    /// Make a versioned `UserPropertiesAPI`.
    ///
    /// - Parameter version: An api version.
    /// - Returns: A versioned `UserPropertiesAPI`.

    public func makeAPI(for version: APIVersion) -> any UserPropertiesAPI {
        switch version {
        case .v0:
            UserPropertiesAPIV0(apiService: apiService)
        case .v1:
            UserPropertiesAPIV1(apiService: apiService)
        case .v2:
            UserPropertiesAPIV2(apiService: apiService)
        case .v3:
            UserPropertiesAPIV3(apiService: apiService)
        case .v4:
            UserPropertiesAPIV4(apiService: apiService)
        case .v5:
            UserPropertiesAPIV5(apiService: apiService)
        case .v6:
            UserPropertiesAPIV6(apiService: apiService)
        case .v7:
            UserPropertiesAPIV7(apiService: apiService)
        case .v8:
            UserPropertiesAPIV8(apiService: apiService)
        case .v9:
            UserPropertiesAPIV9(apiService: apiService)
        case .v10:
            UserPropertiesAPIV10(apiService: apiService)
        case .v11:
            UserPropertiesAPIV11(apiService: apiService)
        case .v12:
            UserPropertiesAPIV12(apiService: apiService)
        case .v13:
            UserPropertiesAPIV13(apiService: apiService)
        case .v14:
            UserPropertiesAPIV14(apiService: apiService)
        }
    }

}
