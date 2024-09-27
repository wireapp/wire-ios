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

// MARK: - APIProviderInterface

// sourcery: AutoMockable
public protocol APIProviderInterface {
    func prekeyAPI(apiVersion: APIVersion) -> PrekeyAPI
    func messageAPI(apiVersion: APIVersion) -> MessageAPI
    func e2eIAPI(apiVersion: APIVersion) -> E2eIAPI?
    func userClientAPI(apiVersion: APIVersion) -> UserClientAPI
}

// MARK: - APIProvider

public struct APIProvider: APIProviderInterface {
    // MARK: Lifecycle

    public init(httpClient: HttpClient) {
        self.httpClient = httpClient
    }

    // MARK: Public

    public func prekeyAPI(apiVersion: APIVersion) -> PrekeyAPI {
        switch apiVersion {
        case .v0: PrekeyAPIV0(httpClient: httpClient)
        case .v1: PrekeyAPIV1(httpClient: httpClient)
        case .v2: PrekeyAPIV2(httpClient: httpClient)
        case .v3: PrekeyAPIV3(httpClient: httpClient)
        case .v4: PrekeyAPIV4(httpClient: httpClient)
        case .v5: PrekeyAPIV5(httpClient: httpClient)
        case .v6: PrekeyAPIV6(httpClient: httpClient)
        }
    }

    public func messageAPI(apiVersion: APIVersion) -> MessageAPI {
        switch apiVersion {
        case .v0: MessageAPIV0(httpClient: httpClient)
        case .v1: MessageAPIV1(httpClient: httpClient)
        case .v2: MessageAPIV2(httpClient: httpClient)
        case .v3: MessageAPIV3(httpClient: httpClient)
        case .v4: MessageAPIV4(httpClient: httpClient)
        case .v5: MessageAPIV5(httpClient: httpClient)
        case .v6: MessageAPIV6(httpClient: httpClient)
        }
    }

    public func e2eIAPI(apiVersion: APIVersion) -> E2eIAPI? {
        switch apiVersion {
        case .v0,
             .v1,
             .v2,
             .v3,
             .v4: nil
        case .v5: E2eIAPIV5(httpClient: httpClient)
        case .v6: E2eIAPIV6(httpClient: httpClient)
        }
    }

    public func userClientAPI(apiVersion: APIVersion) -> UserClientAPI {
        switch apiVersion {
        case .v0: UserClientAPIV0(httpClient: httpClient)
        case .v1: UserClientAPIV1(httpClient: httpClient)
        case .v2: UserClientAPIV2(httpClient: httpClient)
        case .v3: UserClientAPIV3(httpClient: httpClient)
        case .v4: UserClientAPIV4(httpClient: httpClient)
        case .v5: UserClientAPIV5(httpClient: httpClient)
        case .v6: UserClientAPIV6(httpClient: httpClient)
        }
    }

    // MARK: Internal

    let httpClient: HttpClient
}
