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

/// A builder for `AccountsAPI`.

public struct AccountsAPIBuilder {

    let apiService: any APIServiceProtocol

    /// Create a new builder.
    ///
    /// - Parameter httpClient: A http client.

    public init(apiService: any APIServiceProtocol) {
        self.apiService = apiService
    }

    /// Make a versioned `AccountsAPI`.
    ///
    /// - Parameter version: An api version.
    /// - Returns: A versioned `AccountsAPI`.

    public func makeAPI(for version: APIVersion) -> any AccountsAPI {
        switch version {
        case .v0:
            return AccountsAPIV0(apiService: apiService)
        case .v1:
            return AccountsAPIV1(apiService: apiService)
        case .v2:
            return AccountsAPIV2(apiService: apiService)
        case .v3:
            return AccountsAPIV3(apiService: apiService)
        case .v4:
            return AccountsAPIV4(apiService: apiService)
        case .v5:
            return AccountsAPIV5(apiService: apiService)
        case .v6:
            return AccountsAPIV6(apiService: apiService)
        case .v7:
            return AccountsAPIV7(apiService: apiService)
        }
    }
}
