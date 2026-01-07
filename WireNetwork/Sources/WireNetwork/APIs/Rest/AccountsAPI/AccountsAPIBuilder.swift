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

/// A builder for `AccountsAPI`.

public struct AccountsAPIBuilder {

    let apiService: any APIServiceProtocol

    /// Create a new builder.
    ///
    /// - Parameter apiService: An api service.

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
            AccountsAPIV0(apiService: apiService)
        case .v1:
            AccountsAPIV1(apiService: apiService)
        case .v2:
            AccountsAPIV2(apiService: apiService)
        case .v3:
            AccountsAPIV3(apiService: apiService)
        case .v4:
            AccountsAPIV4(apiService: apiService)
        case .v5:
            AccountsAPIV5(apiService: apiService)
        case .v6:
            AccountsAPIV6(apiService: apiService)
        case .v7:
            AccountsAPIV7(apiService: apiService)
        case .v8:
            AccountsAPIV8(apiService: apiService)
        case .v9:
            AccountsAPIV9(apiService: apiService)
        case .v10:
            AccountsAPIV10(apiService: apiService)
        case .v11:
            AccountsAPIV11(apiService: apiService)
        case .v12:
            AccountsAPIV12(apiService: apiService)
        case .v13:
            AccountsAPIV13(apiService: apiService)
        case .v14:
            AccountsAPIV14(apiService: apiService)
        }
    }
}
