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

class UserClientsAPIV2: UserClientsAPIV1 {

    override var apiVersion: APIVersion {
        .v2
    }

    override func getClients(for userIDs: Set<UserID>) async throws -> [OtherUserClients] {
        let components = URLComponents(string: "/users/list-clients")

        guard let url = components?.url else {
            assertionFailure("generated an invalid url")
            throw UserClientsAPIError.invalidURL
        }

        let body = try JSONEncoder.defaultEncoder.encode(
            UserClientsRequestV0(qualifiedIDs: Array(userIDs))
        )

        let request = URLRequestBuilder(url: url)
            .withMethod(.post)
            .withBody(body, contentType: .json)
            .build()

        let (data, response) = try await apiService.executeRequest(
            request,
            requiringAccessToken: true
        )

        return try ResponseParser()
            .success(code: .ok, type: OtherUserClientsV0.self)
            .parse(code: response.statusCode, data: data)
    }

}
