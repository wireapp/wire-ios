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

/// A builder of `ConnectionsAPI`.

public struct ConnectionsAPIBuilder {

    let apiService: any APIServiceProtocol

    /// Create a new builder.
    ///
    /// - Parameter APIService: An api service.

    public init(apiService: any APIServiceProtocol) {
        self.apiService = apiService
    }

    /// Make a versioned `ConnectionsAPI`.
    ///
    /// - Parameter version: An api version.
    /// - Returns: A versioned `ConnectionsAPI`.

    public func makeAPI(for version: APIVersion) -> any ConnectionsAPI {
        switch version {
        case .v0:
            ConnectionsAPIV0(apiService: apiService)
        case .v1:
            ConnectionsAPIV1(apiService: apiService)
        case .v2:
            ConnectionsAPIV2(apiService: apiService)
        case .v3:
            ConnectionsAPIV3(apiService: apiService)
        case .v4:
            ConnectionsAPIV4(apiService: apiService)
        case .v5:
            ConnectionsAPIV5(apiService: apiService)
        case .v6:
            ConnectionsAPIV6(apiService: apiService)
        case .v7:
            ConnectionsAPIV7(apiService: apiService)
        case .v8:
            ConnectionsAPIV8(apiService: apiService)
        case .v9:
            ConnectionsAPIV9(apiService: apiService)
        case .v10:
            ConnectionsAPIV10(apiService: apiService)
        case .v11:
            ConnectionsAPIV11(apiService: apiService)
        case .v12:
            ConnectionsAPIV12(apiService: apiService)
        case .v13:
            ConnectionsAPIV13(apiService: apiService)
        case .v14:
            ConnectionsAPIV14(apiService: apiService)
        }
    }

}
