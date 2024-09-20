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
/// A service for network communication to a specific backend.
///
/// An api service allows api clients to communicate to a target backend.
/// It may provide additional functionality, such as providing authentication
/// headers if needed.
public protocol APIServiceProtocol {

    /// Execute a request to the backend.
    ///
    /// - Parameters:
    ///   - request: A url request.
    ///   - requiringAccessToken: Whether the request requires an access token.
    ///
    /// - Returns: The response to the request.

    func executeRequest(
        _ request: URLRequest,
        requiringAccessToken: Bool
    ) async throws -> (Data, HTTPURLResponse)

}

/// A service for network communication to a specific backend.
///
/// An api service allows api clients to communicate to a target backend.
/// It may provide additional functionality, such providing authentication
/// headers if needed.

public final class APIService: APIServiceProtocol {

    private let clientID: String
    private let authenticationStorage: any AuthenticationStorage
    private let networkService: NetworkService

    /// Create a new `APIService`.
    ///
    /// - Parameters:
    ///   - clientID: The id of the self client.
    ///   - backendURL: The url of the target backend.
    ///   - authenticationStorage: The storage for authentication objects.
    ///   - minTLSVersion: The minimum supported TLS version.

    public convenience init(
        clientID: String,
        backendURL: URL,
        authenticationStorage: any AuthenticationStorage,
        minTLSVersion: TLSVersion
    ) {
        let configFactory = URLSessionConfigurationFactory(minTLSVersion: minTLSVersion)
        let configuration = configFactory.makeRESTAPISessionConfiguration()
        let urlSession = URLSession(configuration: configuration)
        let networkService = NetworkService(baseURL: backendURL, urlSession: urlSession)

        self.init(
            clientID: clientID,
            authenticationStorage: authenticationStorage,
            networkService: networkService
        )
    }

    init(
        clientID: String,
        authenticationStorage: any AuthenticationStorage,
        networkService: NetworkService
    ) {
        self.clientID = clientID
        self.authenticationStorage = authenticationStorage
        self.networkService = networkService
    }

    /// Execute a request to the backend.
    ///
    /// - Parameters:
    ///   - request: A url request.
    ///   - requiringAccessToken: Whether the request requires an access token.
    ///
    /// - Returns: The response to the request.

    public func executeRequest(
        _ request: URLRequest,
        requiringAccessToken: Bool
    ) async throws -> (Data, HTTPURLResponse) {
        var request = request

        if requiringAccessToken {
            let accessToken = try await getAccessToken()
            request.setAccessToken(accessToken)
        }

        return try await networkService.executeRequest(request)
    }

    private func getAccessToken() async throws -> AccessToken {
        guard
            let currentAccessToken = await authenticationStorage.fetchAccessToken(),
            !currentAccessToken.isExpiring
        else {
            let newAccessToken = try await getNewAccessToken()
            await authenticationStorage.storeAccessToken(newAccessToken)
            return newAccessToken
        }

        return currentAccessToken
    }

    private func getNewAccessToken() async throws -> AccessToken {
        let cookies = try await authenticationStorage.fetchCookies()

        var request = try URLRequestBuilder(path: "/access")
            .withQueryItem(name: "client_id", value: clientID)
            .withMethod(.post)
            .withAcceptType(.json)
            .withCookies(cookies)
            .build()

        if let lastKnownAccessToken = await authenticationStorage.fetchAccessToken() {
            request.setAccessToken(lastKnownAccessToken)
        }

        let (data, response) = try await networkService.executeRequest(request)

        return try ResponseParser()
            .success(code: .ok, type: AccessTokenPayload.self)
            .failure(code: .forbidden, label: "invalid-credentials", error: APIServiceError.invalidCredentials)
            .parse(code: response.statusCode, data: data)
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

private extension AccessToken {

    var isExpiring: Bool {
        let secondsRemaining = expirationDate.timeIntervalSinceNow
        return secondsRemaining < 40
    }

}
