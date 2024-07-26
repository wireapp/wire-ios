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

/// Execute url requests to a specific backend.
///
/// The `APIService` connects API clients to a target backend, providing
/// additional services such as attaching an access token if needed.

public final class APIService {

    private let backendURL: URL
    private let backendWebSocketURL: URL
    private let authenticationStorage: any AuthenticationStorage
    private let minTLSVersion: TLSVersion

    private lazy var urlSession: URLSession = {
        let configFactory = URLSessionConfigurationFactory(minTLSVersion: minTLSVersion)
        let configuration = configFactory.makeRESTAPISessionConfiguration()
        return URLSession(configuration: configuration)
    }()

    // TODO: document

    public init(
        backendURL: URL,
        backendWebSocketURL: URL,
        authenticationStorage: any AuthenticationStorage,
        minTLSVersion: TLSVersion
    ) {
        self.backendURL = backendURL
        self.backendWebSocketURL = backendWebSocketURL
        self.authenticationStorage = authenticationStorage
        self.minTLSVersion = minTLSVersion
    }

    func executeRequest(
        _ request: URLRequest,
        requiringAccessToken: Bool
    ) async throws -> (Data, HTTPURLResponse) {
        guard let url = request.url else {
            throw APIServiceError.invalidRequest
        }

        var request = request
        request.url = URL(string: url.absoluteString, relativeTo: backendURL)

        if requiringAccessToken {
            guard let accessToken = authenticationStorage.fetchAccessToken() else {
                // TODO: try to fetch access token.
                throw APIServiceError.missingAccessToken
            }

            // TODO: check for access token expiration.
            request.setAccessToken(accessToken)
        }

        print("executing request: \(request)")

        let (data, response) = try await urlSession.data(for: request)

        print("go response: \(response)")

        guard let httpURLResponse = response as? HTTPURLResponse else {
            throw APIServiceError.notAHTTPURLResponse
        }

        return (data, httpURLResponse)
    }

    func createPushChannel(_ request: URLRequest) throws -> any PushChannelProtocol{
        guard let url = request.url else {
            throw APIServiceError.invalidRequest
        }

        var request = request
        request.url = URL(string: url.absoluteString, relativeTo: backendWebSocketURL)

        guard let accessToken = authenticationStorage.fetchAccessToken() else {
            // TODO: try to fetch access token.
            throw APIServiceError.missingAccessToken
        }

        // TODO: check for access token expiration.
        request.setAccessToken(accessToken)

        return PushChannel(
            request: request,
            minTLSVersion: minTLSVersion
        )
    }

}
