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

// MARK: - APIServiceProtocol

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

// MARK: - APIService

/// A service for network communication to a specific backend.
///
/// An api service allows api clients to communicate to a target backend.
/// It may provide additional functionality, such providing authentication
/// headers if needed.

public final class APIService: APIServiceProtocol {
    private let backendURL: URL
    private let authenticationStorage: any AuthenticationStorage
    private let urlSession: URLSession
    private let minTLSVersion: TLSVersion

    /// Create a new `APIService`.
    ///
    /// - Parameters:
    ///   - backendURL: The url of the target backend.
    ///   - authenticationStorage: The storage for authentication objects.
    ///   - minTLSVersion: The minimum supported TLS version.

    public convenience init(
        backendURL: URL,
        authenticationStorage: any AuthenticationStorage,
        minTLSVersion: TLSVersion
    ) {
        let configFactory = URLSessionConfigurationFactory(minTLSVersion: minTLSVersion)
        let configuration = configFactory.makeRESTAPISessionConfiguration()
        let urlSession = URLSession(configuration: configuration)

        self.init(
            backendURL: backendURL,
            authenticationStorage: authenticationStorage,
            urlSession: urlSession,
            minTLSVersion: minTLSVersion
        )
    }

    init(
        backendURL: URL,
        authenticationStorage: any AuthenticationStorage,
        urlSession: URLSession,
        minTLSVersion: TLSVersion
    ) {
        self.backendURL = backendURL
        self.authenticationStorage = authenticationStorage
        self.urlSession = urlSession
        self.minTLSVersion = minTLSVersion
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
        guard let url = request.url else {
            throw APIServiceError.invalidRequest
        }

        var request = request
        request.url = URL(
            string: url.absoluteString,
            relativeTo: backendURL
        )

        if requiringAccessToken {
            guard let accessToken = authenticationStorage.fetchAccessToken() else {
                throw APIServiceError.missingAccessToken
            }

            request.setAccessToken(accessToken)
        }

        let (data, response) = try await urlSession.data(for: request)

        guard let httpURLResponse = response as? HTTPURLResponse else {
            throw APIServiceError.notAHTTPURLResponse
        }

        return (data, httpURLResponse)
    }
}
