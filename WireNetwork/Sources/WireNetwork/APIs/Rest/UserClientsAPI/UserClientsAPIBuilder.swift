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

/// A builder of `UserClientsAPI`.

public struct UserClientsAPIBuilder {

    let apiService: any APIServiceProtocol

    /// Create a new builder.
    ///
    /// - Parameter APIService: An api service.

    public init(apiService: any APIServiceProtocol) {
        self.apiService = apiService
    }

    /// Make a versioned `UserClientsAPI`.
    ///
    /// - Parameter version: An api version.
    /// - Returns: A versioned `UserClientsAPI`.

    public func makeAPI(for version: APIVersion) -> any UserClientsAPI {
        switch version {
        case .v0:
            UserClientsAPIV0(apiService: apiService)
        case .v1:
            UserClientsAPIV1(apiService: apiService)
        case .v2:
            UserClientsAPIV2(apiService: apiService)
        case .v3:
            UserClientsAPIV3(apiService: apiService)
        case .v4:
            UserClientsAPIV4(apiService: apiService)
        case .v5:
            UserClientsAPIV5(apiService: apiService)
        case .v6:
            UserClientsAPIV6(apiService: apiService)
        case .v7:
            UserClientsAPIV7(apiService: apiService)
        case .v8:
            UserClientsAPIV8(apiService: apiService)
        case .v9:
            UserClientsAPIV9(apiService: apiService)
        case .v10:
            UserClientsAPIV10(apiService: apiService)
        case .v11:
            UserClientsAPIV11(apiService: apiService)
        case .v12:
            UserClientsAPIV12(apiService: apiService)
        case .v13:
            UserClientsAPIV13(apiService: apiService)
        }
    }

}
