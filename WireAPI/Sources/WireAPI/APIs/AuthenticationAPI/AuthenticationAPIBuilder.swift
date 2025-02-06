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

/// A builder for `AuthenticationAPI`.

public struct AuthenticationAPIBuilder {

    let apiService: any APIServiceProtocol

    /// Create a new builder.
    ///
    /// - Parameter apiService: An api service.

    public init(apiService: any APIServiceProtocol) {
        self.apiService = apiService
    }

    /// Make a versioned `AuthenticationAPI`.
    ///
    /// - Parameter version: An api version.
    /// - Returns: A versioned `AuthenticationAPI`.

    public func makeAPI(for version: APIVersion) -> any AuthenticationAPI {
        switch version {
        case .v0:
            AuthenticationAPIV0(apiService: apiService)
        case .v1:
            AuthenticationAPIV1(apiService: apiService)
        case .v2:
            AuthenticationAPIV2(apiService: apiService)
        case .v3:
            AuthenticationAPIV3(apiService: apiService)
        case .v4:
            AuthenticationAPIV4(apiService: apiService)
        case .v5:
            AuthenticationAPIV5(apiService: apiService)
        case .v6:
            AuthenticationAPIV6(apiService: apiService)
        case .v7:
            AuthenticationAPIV7(apiService: apiService)
        case .v8:
            AuthenticationAPIV8(apiService: apiService)
        }
    }
}
