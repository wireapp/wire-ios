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

public struct SearchAPIBuilder {

    let apiService: any APIServiceProtocol

    public init(apiService: any APIServiceProtocol) {
        self.apiService = apiService
    }

    /// Make a versioned`SearchAPI`.
    ///
    /// - Parameter version: An api version.
    /// - Returns: A versioned `SearchAPI`.

    public func makeAPI(for version: APIVersion) -> any SearchAPI {
        switch version {
        case .v0:
            SearchAPIV0(apiService: apiService)
        case .v1:
            SearchAPIV1(apiService: apiService)
        case .v2:
            SearchAPIV2(apiService: apiService)
        case .v3:
            SearchAPIV3(apiService: apiService)
        case .v4:
            SearchAPIV4(apiService: apiService)
        case .v5:
            SearchAPIV5(apiService: apiService)
        case .v6:
            SearchAPIV6(apiService: apiService)
        case .v7:
            SearchAPIV7(apiService: apiService)
        case .v8:
            SearchAPIV8(apiService: apiService)
        case .v9:
            SearchAPIV9(apiService: apiService)
        case .v10:
            SearchAPIV10(apiService: apiService)
        case .v11:
            SearchAPIV11(apiService: apiService)
        case .v12:
            SearchAPIV12(apiService: apiService)
        case .v13:
            SearchAPIV13(apiService: apiService)
        case .v14:
            SearchAPIV14(apiService: apiService)
        case .v15:
            SearchAPIV15(apiService: apiService)
        }
    }
}
