//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
import WireLogging

// sourcery: AutoMockable
public protocol AuthenticationManagerProtocol {

    func getValidAccessToken() async throws -> AccessToken
    func refreshAccessToken() async throws -> AccessToken

}

public actor AuthenticationManager: AuthenticationManagerProtocol {

    enum Failure: Error, Equatable {

        case invalidCredentials

    }

    private enum CurrentToken {

        case cached(AccessToken)
        case renewing(Task<AccessToken, any Error>)

    }

    private var currentToken: CurrentToken?
    private let clientID: String?
    private let cookieStorage: any CookieStorageProtocol
    private let networkService: any NetworkServiceProtocol
    private let onAuthenticationFailure: () -> Void

    public init(
        clientID: String?,
        cookieStorage: any CookieStorageProtocol,
        networkService: any NetworkServiceProtocol,
        onAuthenticationFailure: @escaping () -> Void
    ) {
        self.clientID = clientID
        self.cookieStorage = cookieStorage
        self.networkService = networkService
        self.onAuthenticationFailure = onAuthenticationFailure
    }

    /// Get a valid access token to make authenticated requests.
    ///
    /// If a valid token exists in the cache then it will be returned,
    /// otherwise a new token will be retrieved from the backend.
    ///
    /// - Returns: A valid (non-expired) access token.

    public func getValidAccessToken() async throws -> AccessToken {
        switch currentToken {
        case let .renewing(task):
            // A new token will come soon, wait
            try await task.value

        case let .cached(accessToken) where !accessToken.isExpiring:
            // This one is still good.
            accessToken

        default:
            // Time for a new token.
            try await refreshAccessToken()
        }
    }

    /// Get a new access token from the backend.
    ///
    /// This method will fetch a new access token from the backend
    /// and then store it in the cache. Only a single request is made
    /// at a time, and repeated calls will await the result of any
    /// in-flight requests.
    ///
    /// - Returns: A new access token.

    public func refreshAccessToken() async throws -> AccessToken {
        if case let .renewing(task) = currentToken {
            // A new token will come soon, wait
            return try await task.value
        }

        var lastKnownToken: AccessToken?
        if case let .cached(token) = currentToken {
            lastKnownToken = token
        }

        let task = makeRenewTokenTask(lastKnownToken: lastKnownToken)
        currentToken = .renewing(task)

        do {
            let newToken = try await task.value
            currentToken = .cached(newToken)
            return newToken
        } catch {
            let errorMessage = SafePublicLoggable(String(describing: error))
            WireLogger.authentication.error("Failed to renew access token with error: \(errorMessage)")

            currentToken = nil

            switch error {
            case let authenticationError as AuthenticationManager.Failure:
                switch authenticationError {
                case .invalidCredentials:
                    // can't recover, deleting cookies and logging out
                    try await cookieStorage.removeCookies()
                    WireLogger.authentication.info("Removed cookies (invalidCredentials)")

                    onAuthenticationFailure()
                }

            default:
                break
            }

            throw error
        }
    }

    private func makeRenewTokenTask(
        lastKnownToken: AccessToken?
    ) -> Task<AccessToken, any Error> {
        Task {
            let cookies = try await cookieStorage.fetchCookies()

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

            if let lastKnownToken {
                request.setAccessToken(lastKnownToken)
            }

            let (data, response) = try await networkService.executeRequest(request)

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase

            return try ResponseParser(decoder: decoder)
                .success(code: .ok, type: AccessTokenPayload.self)
                .failure(code: .forbidden, label: "invalid-credentials", error: Failure.invalidCredentials)
                .parse(code: response.statusCode, data: data)
        }
    }

}

extension AccessToken {

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

    func toAPIModel() -> AccessToken {
        AccessToken(
            userID: user,
            token: accessToken,
            type: tokenType,
            expirationDate: Date(timeIntervalSinceNow: TimeInterval(expiresIn))
        )
    }

}
