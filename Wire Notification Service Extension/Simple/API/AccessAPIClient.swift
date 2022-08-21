//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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
import WireTransport

@available(iOS 15, *)
final class AccessAPIClient {

    // MARK: - Properties

    private let networkSession: NetworkSession

    // MARK: - Life cycle

    init(networkSession: NetworkSession) {
        self.networkSession = networkSession
    }

    // MARK: - Methods

    func fetchAccessToken() async throws -> AccessToken {
        switch try await networkSession.execute(endpoint: API.fetchAccessToken()) {
        case .success(let accessToken):
            return accessToken

        case .failure(let error):
            throw error
        }
    }

}

struct AccessTokenEndpoint: Endpoint {

    // MARK: - Types

    typealias Output = AccessToken

    enum Failure: Error {

        case invalidResponse
        case failedToDecodePayload
        case authenticationError
        case unknownError(status: Int, label: String)

    }

    // MARK: - Request

    let request = NetworkRequest(
        path: "/access",
        httpMethod: .post,
        contentType: .json,
        acceptType: .json
    )

    // MARK: - Response

    private struct ResponsePayload: Codable {

        let access_token: String
        let expires_in: Int
        let token_type: String
    }

    func parseResponse(_ response: NetworkResponse) -> Swift.Result<Output, Failure> {
        switch response.status {
        case 200:
            do {
                let payload = try JSONDecoder().decode(ResponsePayload.self, from: response.data)

                return .success(AccessToken(
                    token: payload.access_token,
                    type: payload.token_type,
                    expiresInSeconds: UInt(payload.expires_in)
                ))
            } catch {
                return .failure(.failedToDecodePayload)
            }

        case 403:
            return .failure(.authenticationError)

        case let status:
            return .failure(.unknownError(status: status, label: "TODO"))
        }

    }

}
