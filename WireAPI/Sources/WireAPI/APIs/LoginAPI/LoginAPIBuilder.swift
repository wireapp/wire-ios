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

/// Builder for the Login API.
struct LoginAPIBuilder {

    let networkService: NetworkService

    /// Create a new builder.
    ///
    /// - Parameter NetworkService: The service for making network requests.
    init(networkService: NetworkService) {
        self.networkService = networkService
    }

    /// Make a versioned `LoginAPI`.
    ///
    /// - Parameter version: An api version.
    /// - Returns: A versioned `LoginAPI`.
    func makeAPI(for version: APIVersion) -> any LoginAPI {
        switch version {
        case .v0:
            LoginAPIV0(networkService: networkService)
        case .v1:
            LoginAPIV1(networkService: networkService)
        case .v2:
            LoginAPIV2(networkService: networkService)
        case .v3:
            LoginAPIV3(networkService: networkService)
        case .v4:
            LoginAPIV4(networkService: networkService)
        case .v5:
            LoginAPIV5(networkService: networkService)
        case .v6:
            LoginAPIV6(networkService: networkService)
        }
    }

}
