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

// sourcery: AutoMockable
public protocol APIProviderInterface {
    func prekeyAPI(apiVersion: APIVersion) -> PrekeyAPI
    func messageAPI(apiVersion: APIVersion) -> MessageAPI
    func e2eIAPI(apiVersion: APIVersion) -> E2eIAPI?
    func userClientAPI(apiVersion: APIVersion) -> UserClientAPI
}

public struct APIProvider: APIProviderInterface {

    let httpClient: HttpClient

    public init(httpClient: HttpClient) {
        self.httpClient = httpClient
    }

    public func prekeyAPI(apiVersion: APIVersion) -> PrekeyAPI {
        switch apiVersion {
        case .v0: PrekeyAPIV0(httpClient: httpClient)
        case .v1: PrekeyAPIV1(httpClient: httpClient)
        case .v2: PrekeyAPIV2(httpClient: httpClient)
        case .v3: PrekeyAPIV3(httpClient: httpClient)
        case .v4: PrekeyAPIV4(httpClient: httpClient)
        case .v5: PrekeyAPIV5(httpClient: httpClient)
        case .v6: PrekeyAPIV6(httpClient: httpClient)
        case .v7: PrekeyAPIV7(httpClient: httpClient)
        case .v8: PrekeyAPIV8(httpClient: httpClient)
        case .v9: PrekeyAPIV9(httpClient: httpClient)
        case .v10: PrekeyAPIV10(httpClient: httpClient)
        case .v11: PrekeyAPIV11(httpClient: httpClient)
        case .v12: PrekeyAPIV12(httpClient: httpClient)
        case .v13: PrekeyAPIV13(httpClient: httpClient)
        case .v14: PrekeyAPIV14(httpClient: httpClient)
        case .v15: PrekeyAPIV15(httpClient: httpClient)
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
        case .v7: MessageAPIV7(httpClient: httpClient)
        case .v8: MessageAPIV8(httpClient: httpClient)
        case .v9: MessageAPIV9(httpClient: httpClient)
        case .v10: MessageAPIV10(httpClient: httpClient)
        case .v11: MessageAPIV11(httpClient: httpClient)
        case .v12: MessageAPIV12(httpClient: httpClient)
        case .v13: MessageAPIV13(httpClient: httpClient)
        case .v14: MessageAPIV14(httpClient: httpClient)
        case .v15: MessageAPIV15(httpClient: httpClient)
        }
    }

    public func e2eIAPI(apiVersion: APIVersion) -> E2eIAPI? {
        switch apiVersion {
        case .v0, .v1, .v2, .v3, .v4: nil
        case .v5: E2eIAPIV5(httpClient: httpClient)
        case .v6: E2eIAPIV6(httpClient: httpClient)
        case .v7: E2eIAPIV7(httpClient: httpClient)
        case .v8: E2eIAPIV8(httpClient: httpClient)
        case .v9: E2eIAPIV9(httpClient: httpClient)
        case .v10: E2eIAPIV10(httpClient: httpClient)
        case .v11: E2eIAPIV11(httpClient: httpClient)
        case .v12: E2eIAPIV12(httpClient: httpClient)
        case .v13: E2eIAPIV13(httpClient: httpClient)
        case .v14: E2eIAPIV14(httpClient: httpClient)
        case .v15: E2eIAPIV15(httpClient: httpClient)
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
        case .v7: UserClientAPIV7(httpClient: httpClient)
        case .v8: UserClientAPIV8(httpClient: httpClient)
        case .v9: UserClientAPIV9(httpClient: httpClient)
        case .v10: UserClientAPIV10(httpClient: httpClient)
        case .v11: UserClientAPIV11(httpClient: httpClient)
        case .v12: UserClientAPIV12(httpClient: httpClient)
        case .v13: UserClientAPIV13(httpClient: httpClient)
        case .v14: UserClientAPIV14(httpClient: httpClient)
        case .v15: UserClientAPIV15(httpClient: httpClient)
        }
    }
}
