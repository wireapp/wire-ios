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

/// A builder for `AuthenticationAPI`.

public struct AuthenticationAPIBuilder {

    let networkService: any NetworkServiceProtocol

    /// Create a new builder.
    ///
    /// - Parameter apiService: An api service.

    public init(networkService: any NetworkServiceProtocol) {
        self.networkService = networkService
    }

    /// Make a versioned `AuthenticationAPI`.
    ///
    /// - Parameter version: An api version.
    /// - Returns: A versioned `AuthenticationAPI`.

    public func makeAPI(for version: APIVersion) -> some AuthenticationAPI {
        switch version {
        case .v0:
            AuthenticationAPIV0(networkService: networkService)
        case .v1:
            AuthenticationAPIV1(networkService: networkService)
        case .v2:
            AuthenticationAPIV2(networkService: networkService)
        case .v3:
            AuthenticationAPIV3(networkService: networkService)
        case .v4:
            AuthenticationAPIV4(networkService: networkService)
        case .v5:
            AuthenticationAPIV5(networkService: networkService)
        case .v6:
            AuthenticationAPIV6(networkService: networkService)
        case .v7:
            AuthenticationAPIV7(networkService: networkService)
        case .v8:
            AuthenticationAPIV8(networkService: networkService)
        case .v9:
            AuthenticationAPIV9(networkService: networkService)
        case .v10:
            AuthenticationAPIV10(networkService: networkService)
        case .v11:
            AuthenticationAPIV11(networkService: networkService)
        case .v12:
            AuthenticationAPIV12(networkService: networkService)
        case .v13:
            AuthenticationAPIV13(networkService: networkService)
        }
    }
}
