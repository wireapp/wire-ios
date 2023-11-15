////
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

public struct APIProvider {

    let httpClient: HttpClient

    public init(httpClient: HttpClient) {
        self.httpClient = httpClient
    }

    func prekeyAPI(apiVersion: APIVersion) -> PrekeyAPI {
        return switch apiVersion {
        case .v0: PrekeyAPIV0(httpClient: httpClient)
        case .v1: PrekeyAPIV1(httpClient: httpClient)
        case .v2: PrekeyAPIV2(httpClient: httpClient)
        case .v3: PrekeyAPIV3(httpClient: httpClient)
        case .v4: PrekeyAPIV4(httpClient: httpClient)
        case .v5: PrekeyAPIV5(httpClient: httpClient)
        }
    }

    func messageAPI(apiVersion: APIVersion) -> MessageAPI {
        return switch apiVersion {
        case .v0: MessageAPIV0(httpClient: httpClient)
        case .v1: MessageAPIV1(httpClient: httpClient)
        case .v2: MessageAPIV2(httpClient: httpClient)
        case .v3: MessageAPIV3(httpClient: httpClient)
        case .v4: MessageAPIV4(httpClient: httpClient)
        case .v5: MessageAPIV5(httpClient: httpClient)
        }
    }
}
