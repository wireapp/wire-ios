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
import WireTransport

// MARK: - AccessAPIClientProtocol

protocol AccessAPIClientProtocol {
    func fetchAccessToken() async throws -> AccessToken
}

// MARK: - AccessAPIClient

final class AccessAPIClient: AccessAPIClientProtocol, Loggable {
    // MARK: Lifecycle

    init(networkSession: NetworkSessionProtocol) {
        self.networkSession = networkSession
    }

    // MARK: Internal

    // MARK: - Methods

    func fetchAccessToken() async throws -> AccessToken {
        logger.trace("fetching access token")
        switch try await networkSession.execute(endpoint: API.fetchAccessToken()) {
        case let .success(accessToken):
            return accessToken

        case let .failure(error):
            throw error
        }
    }

    // MARK: Private

    // MARK: - Properties

    private let networkSession: NetworkSessionProtocol
}

// MARK: - AccessTokenEndpoint

struct AccessTokenEndpoint: Endpoint, Loggable {
    // MARK: Internal

    // MARK: - Types

    typealias Output = AccessToken

    enum Failure: Error, Equatable {
        case invalidResponse
        case failedToDecodePayload
        case authenticationError
        case unknownError(ErrorResponse)
    }

    // MARK: - Request

    let request = NetworkRequest(
        path: "/access",
        httpMethod: .post,
        contentType: .json,
        acceptType: .json
    )

    func parseResponse(_ response: NetworkResponse) -> Result<Output, Failure> {
        logger.trace("parsing reponse: \(response, privacy: .public)")

        switch response {
        case let .success(response) where response.status == 200:
            do {
                logger.trace("decoding response payload")
                let payload = try JSONDecoder().decode(ResponsePayload.self, from: response.data)

                return .success(AccessToken(
                    token: payload.access_token,
                    type: payload.token_type,
                    expiresInSeconds: UInt(payload.expires_in)
                ))
            } catch {
                return .failure(.failedToDecodePayload)
            }

        case let .failure(response):
            switch (response.code, response.label) {
            case (403, "invalid-credentials"):
                return .failure(.authenticationError)

            default:
                return .failure(.unknownError(response))
            }

        default:
            return .failure(.invalidResponse)
        }
    }

    // MARK: Private

    // MARK: - Response

    private struct ResponsePayload: Codable {
        let access_token: String
        let expires_in: Int
        let token_type: String
    }
}
