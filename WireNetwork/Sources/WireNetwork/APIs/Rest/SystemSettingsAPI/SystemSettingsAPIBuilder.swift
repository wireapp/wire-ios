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

/// A builder of `SystemSettingsAPI`.

public struct SystemSettingsAPIBuilder {

    let networkService: any NetworkServiceProtocol

    /// Create a new builder.
    ///
    /// - Parameter networkService: A service for executing requests.

    public init(networkService: any NetworkServiceProtocol) {
        self.networkService = networkService
    }

    /// Make a versioned `SystemSettingsAPI`.
    ///
    /// - Parameter version: An api version.
    /// - Returns: A versioned `SystemSettingsAPI`.

    public func makeAPI(for version: APIVersion) -> any SystemSettingsAPI {
        switch version {
        case .v0:
            SystemSettingsAPIV0(networkService: networkService)
        case .v1:
            SystemSettingsAPIV1(networkService: networkService)
        case .v2:
            SystemSettingsAPIV2(networkService: networkService)
        case .v3:
            SystemSettingsAPIV3(networkService: networkService)
        case .v4:
            SystemSettingsAPIV4(networkService: networkService)
        case .v5:
            SystemSettingsAPIV5(networkService: networkService)
        case .v6:
            SystemSettingsAPIV6(networkService: networkService)
        case .v7:
            SystemSettingsAPIV7(networkService: networkService)
        case .v8:
            SystemSettingsAPIV8(networkService: networkService)
        case .v9:
            SystemSettingsAPIV9(networkService: networkService)
        case .v10:
            SystemSettingsAPIV10(networkService: networkService)
        case .v11:
            SystemSettingsAPIV11(networkService: networkService)
        case .v12:
            SystemSettingsAPIV12(networkService: networkService)
        case .v13:
            SystemSettingsAPIV13(networkService: networkService)
        case .v14:
            SystemSettingsAPIV14(networkService: networkService)
        case .v15:
            SystemSettingsAPIV15(networkService: networkService)
        case .v16:
            SystemSettingsAPIV16(networkService: networkService)
        case .v17:
            SystemSettingsAPIV17(networkService: networkService)
        case .v18:
            SystemSettingsAPIV18(networkService: networkService)
        }
    }

}
