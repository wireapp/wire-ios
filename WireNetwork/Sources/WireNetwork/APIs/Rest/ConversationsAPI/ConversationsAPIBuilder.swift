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

/// Builder for the conversations API.
public struct ConversationsAPIBuilder {

    let apiService: any APIServiceProtocol

    /// Create a new builder.
    ///
    /// - Parameter APIService: An api service.

    public init(apiService: any APIServiceProtocol) {
        self.apiService = apiService
    }

    /// Make a versioned `ConversationsAPI`.
    ///
    /// - Parameter version: An api version.
    /// - Returns: A versioned `ConversationsAPI`.
    public func makeAPI(for version: APIVersion) -> any ConversationsAPI {
        switch version {
        case .v0:
            ConversationsAPIV0(apiService: apiService)
        case .v1:
            ConversationsAPIV1(apiService: apiService)
        case .v2:
            ConversationsAPIV2(apiService: apiService)
        case .v3:
            ConversationsAPIV3(apiService: apiService)
        case .v4:
            ConversationsAPIV4(apiService: apiService)
        case .v5:
            ConversationsAPIV5(apiService: apiService)
        case .v6:
            ConversationsAPIV6(apiService: apiService)
        case .v7:
            ConversationsAPIV7(apiService: apiService)
        case .v8:
            ConversationsAPIV8(apiService: apiService)
        case .v9:
            ConversationsAPIV9(apiService: apiService)
        case .v10:
            ConversationsAPIV10(apiService: apiService)
        case .v11:
            ConversationsAPIV11(apiService: apiService)
        case .v12:
            ConversationsAPIV12(apiService: apiService)
        case .v13:
            ConversationsAPIV13(apiService: apiService)
        }
    }

}
