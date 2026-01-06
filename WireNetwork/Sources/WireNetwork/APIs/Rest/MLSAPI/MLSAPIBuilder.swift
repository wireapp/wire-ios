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

/// A builder of `MLSAPI`.

public struct MLSAPIBuilder {

    let apiService: any APIServiceProtocol

    /// Create a new builder.
    ///
    /// - Parameter apiService: A service for executing requests.`

    public init(apiService: any APIServiceProtocol) {
        self.apiService = apiService
    }

    /// Make a `MLSAPI`.
    ///
    /// - Parameter version: An api version.
    /// - Returns: A `MLSAPI`.

    public func makeAPI(for version: APIVersion) -> some MLSAPI {
        switch version {
        case .v0:
            MLSAPIV0(apiService: apiService)
        case .v1:
            MLSAPIV1(apiService: apiService)
        case .v2:
            MLSAPIV2(apiService: apiService)
        case .v3:
            MLSAPIV3(apiService: apiService)
        case .v4:
            MLSAPIV4(apiService: apiService)
        case .v5:
            MLSAPIV5(apiService: apiService)
        case .v6:
            MLSAPIV6(apiService: apiService)
        case .v7:
            MLSAPIV7(apiService: apiService)
        case .v8:
            MLSAPIV8(apiService: apiService)
        case .v9:
            MLSAPIV9(apiService: apiService)
        case .v10:
            MLSAPIV10(apiService: apiService)
        case .v11:
            MLSAPIV11(apiService: apiService)
        case .v12:
            MLSAPIV12(apiService: apiService)
        case .v13:
            MLSAPIV13(apiService: apiService)
        case .v14:
            MLSAPIV14(apiService: apiService)
        }
    }

}
