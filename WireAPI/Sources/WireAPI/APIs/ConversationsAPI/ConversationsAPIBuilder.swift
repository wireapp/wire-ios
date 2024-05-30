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

/// Builder for the conversations API.
public struct ConversationsAPIBuilder: APIBuilder {

    private let httpClient: any HTTPClient
    private let backendInfo: BackendInfo

    /// Create a new builder for the conversations API.
    ///
    /// - Parameter httpClient: A http client.
    public init(httpClient: any HTTPClient, backendInfo: BackendInfo) {
        self.httpClient = httpClient
        self.backendInfo = backendInfo
    }

    public init(httpClient: any HTTPClient) {
        self.httpClient = httpClient
        self.backendInfo = .init(
            domain: "",
            isFederationEnabled: true,
            supportedVersions: .init(),
            developmentVersions: .init()
        )
    }

    /// Make a versioned `ConversationsAPI`.
    ///
    /// - Parameter version: An api version.
    /// - Returns: A versioned `ConversationsAPI`.
    public func makeAPI(for version: APIVersion) -> any ConversationsAPI {
        switch version {
        case .v0:
            ConversationsAPIV0(httpClient: httpClient, backendInfo: backendInfo)
        case .v1:
            // TODO: we only need backend info for V0, but now pass to all?
            ConversationsAPIV1(httpClient: httpClient, backendInfo: backendInfo)
        case .v2:
            ConversationsAPIV2(httpClient: httpClient, backendInfo: backendInfo)
        case .v3:
            ConversationsAPIV3(httpClient: httpClient, backendInfo: backendInfo)
        case .v4:
            ConversationsAPIV4(httpClient: httpClient, backendInfo: backendInfo)
        case .v5:
            ConversationsAPIV5(httpClient: httpClient, backendInfo: backendInfo)
        case .v6:
            ConversationsAPIV6(httpClient: httpClient, backendInfo: backendInfo)
        }
    }

}
