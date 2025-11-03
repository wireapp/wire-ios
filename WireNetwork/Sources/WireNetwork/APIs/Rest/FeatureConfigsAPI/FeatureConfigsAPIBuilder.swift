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

/// A builder of `FeatureConfigsAPI`.

public struct FeatureConfigsAPIBuilder {

    let apiService: any APIServiceProtocol

    /// Create a new builder.
    ///
    /// - Parameter APIService: An api service.

    public init(apiService: any APIServiceProtocol) {
        self.apiService = apiService
    }

    /// Make a versioned `FeatureConfigsAPI`.
    ///
    /// - Parameter version: An api version.
    /// - Returns: A versioned `FeatureConfigsAPI`.

    public func makeAPI(for version: APIVersion) -> any FeatureConfigsAPI {
        switch version {
        case .v0:
            FeatureConfigsAPIV0(apiService: apiService)
        case .v1:
            FeatureConfigsAPIV1(apiService: apiService)
        case .v2:
            FeatureConfigsAPIV2(apiService: apiService)
        case .v3:
            FeatureConfigsAPIV3(apiService: apiService)
        case .v4:
            FeatureConfigsAPIV4(apiService: apiService)
        case .v5:
            FeatureConfigsAPIV5(apiService: apiService)
        case .v6:
            FeatureConfigsAPIV6(apiService: apiService)
        case .v7:
            FeatureConfigsAPIV7(apiService: apiService)
        case .v8:
            FeatureConfigsAPIV8(apiService: apiService)
        case .v9:
            FeatureConfigsAPIV9(apiService: apiService)
        case .v10:
            FeatureConfigsAPIV10(apiService: apiService)
        case .v11:
            FeatureConfigsAPIV11(apiService: apiService)
        case .v12:
            FeatureConfigsAPIV12(apiService: apiService)
        case .v13:
            FeatureConfigsAPIV13(apiService: apiService)
        }
    }
}
