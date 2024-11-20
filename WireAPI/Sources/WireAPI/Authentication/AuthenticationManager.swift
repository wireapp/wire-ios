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
import WireFoundation

// sourcery: AutoMockable
protocol AuthenticationManagerProtocol {

    func getValidAccessToken() async throws -> AccessToken
    func refreshAccessToken() async throws -> AccessToken

}

actor AuthenticationManager: AuthenticationManagerProtocol {

    private var currentToken: CurrentToken?
    private let clientID: String
    private let cookieStorage: CookieStorage
    private let networkService: NetworkService

    init(
        clientID: String,
        cookieStorage: CookieStorage,
        networkService: NetworkService
    ) {
        self.clientID = clientID
        self.cookieStorage = cookieStorage
        self.networkService = networkService
    }

    func getValidAccessToken() async throws -> AccessToken {
        switch currentToken {
        case .renewing(let task):
            return try await task.value

        case .cached(let accessToken) where !accessToken.isExpiring:
            return accessToken

        default:
            return try await refreshAccessToken()
        }
    }

    func refreshAccessToken() async throws -> AccessToken {
        switch currentToken {
        case .renewing(let task):
            // A request is in flight, we wait for its result.
            return try await task.value

        case .cached(let accessToken):
            // We are renewing a token.
            let task = makeRenewTokenTask(lastKnownAccessToken: accessToken)
            currentToken = .renewing(task)
            return try await task.value

        default:
            // We are getting the first token.
            let task = makeRenewTokenTask(lastKnownAccessToken: nil)
            currentToken = .renewing(task)
            return try await task.value
        }
    }

    private func makeRenewTokenTask(
        lastKnownAccessToken: AccessToken?
    ) -> Task<AccessToken, any Error> {
        Task {
            let cookies = try await cookieStorage.fetchCookies()

            var request = try URLRequestBuilder(path: "/access")
                .withQueryItem(name: "client_id", value: clientID)
                .withMethod(.post)
                .withAcceptType(.json)
                .withCookies(cookies)
                .build()

            if let lastKnownAccessToken {
                request.setAccessToken(lastKnownAccessToken)
            }

            let (data, response) = try await networkService.executeRequest(request)

            let accessToken = try ResponseParser()
                .success(code: .ok, type: AccessTokenPayload.self)
                .failure(code: .forbidden, label: "invalid-credentials", error: APIServiceError.invalidCredentials)
                .parse(code: response.statusCode, data: data)

            currentToken = .cached(accessToken)
            return accessToken
        }
    }

}

private extension AuthenticationManager {

    enum CurrentToken {

        case cached(AccessToken)
        case renewing(Task<AccessToken, any Error>)

    }

}

private extension AccessToken {

    var isExpiring: Bool {
        let secondsRemaining = expirationDate.timeIntervalSinceNow
        return secondsRemaining < 40
    }

}

private struct AccessTokenPayload: Decodable, ToAPIModelConvertible {

    let user: UUID
    let accessToken: String
    let tokenType: String
    let expiresIn: Int

    enum CodingKeys: String, CodingKey {

        case user
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"

    }

    func toAPIModel() -> AccessToken {
        AccessToken(
            userID: user,
            token: accessToken,
            type: tokenType,
            expirationDate: Date(timeIntervalSinceNow: TimeInterval(expiresIn))
        )
    }

}
