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
/// Exchanges authentication cookies for an access token via `POST /access`.
public protocol AccessTokenExchangeProtocol: Sendable {

    /// Exchange cookies for a fresh access token.
    ///
    /// - Parameters:
    ///   - cookies: The authentication cookies to exchange.
    ///   - clientID: The id of the registered client, if any.
    ///   - lastKnownAccessToken: The last known access token, if any, to include
    ///     alongside the cookies on the renewal request.
    /// - Returns: A fresh access token.

    func exchange(
        cookies: [HTTPCookie],
        clientID: String?,
        lastKnownAccessToken: AccessToken?
    ) async throws -> AccessToken

}

public struct AccessTokenExchange: AccessTokenExchangeProtocol {

    private let networkService: any NetworkServiceProtocol

    public init(networkService: any NetworkServiceProtocol) {
        self.networkService = networkService
    }

    public func exchange(
        cookies: [HTTPCookie],
        clientID: String?,
        lastKnownAccessToken: AccessToken?
    ) async throws -> AccessToken {
        var requestBuilder = try URLRequestBuilder(path: "/access")
            .withMethod(.post)
            .withAcceptType(.json)
            .withCookies(cookies)

        if let clientID {
            requestBuilder = requestBuilder.withQueryItem(
                name: "client_id",
                value: clientID
            )
        }

        var request = requestBuilder.build()

        if let lastKnownAccessToken {
            request.setAccessToken(lastKnownAccessToken)
        }

        let (data, response) = try await networkService.executeRequest(request)

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        return try ResponseParser(decoder: decoder)
            .success(code: .ok, type: AccessTokenPayload.self)
            .failure(
                code: .forbidden,
                label: "invalid-credentials",
                error: AuthenticationManager.Failure.invalidCredentials
            )
            .parse(code: response.statusCode, data: data)
    }

}

struct AccessTokenPayload: Decodable, ToAPIModelConvertible {

    let user: UUID
    let accessToken: String
    let tokenType: String
    let expiresIn: Int

    func toAPIModel() -> AccessToken {
        AccessToken(
            userID: user,
            token: accessToken,
            type: tokenType,
            expirationDate: Date(timeIntervalSinceNow: TimeInterval(expiresIn))
        )
    }

}
