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

// sourcery: AutoMockable
public protocol UserClientAPI {
    func deleteUserClient(clientId: String, password: String) async throws
}

class UserClientAPIV0: UserClientAPI {
    let httpClient: HttpClient

    init(httpClient: HttpClient) {
        self.httpClient = httpClient
    }

    open var apiVersion: APIVersion {
        .v0
    }

    func deleteUserClient(clientId: String, password: String) async throws {
        let requestsFactory = UserClientRequestFactory()

        let request = requestsFactory.deleteClientRequest(
            clientId: clientId,
            password: password,
            apiVersion: apiVersion
        )

        let response = await httpClient.send(request)
        if response.result != .success {
            let error = mapFailureResponse(response)
            throw error
        }
    }
}

class UserClientAPIV1: UserClientAPIV0 {
    override var apiVersion: APIVersion {
        .v1
    }
}

class UserClientAPIV2: UserClientAPIV1 {
    override var apiVersion: APIVersion {
        .v2
    }
}

class UserClientAPIV3: UserClientAPIV2 {
    override var apiVersion: APIVersion {
        .v3
    }
}

class UserClientAPIV4: UserClientAPIV3 {
    override var apiVersion: APIVersion {
        .v4
    }
}

class UserClientAPIV5: UserClientAPIV4 {
    override var apiVersion: APIVersion {
        .v5
    }
}

class UserClientAPIV6: UserClientAPIV5 {
    override var apiVersion: APIVersion {
        .v6
    }
}
