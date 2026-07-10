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

public import Foundation

import WireFoundation

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

    private let networkService: NetworkService
    private let authenticationManager: any AuthenticationManagerProtocol

    public init(
        networkService: NetworkService,
        authenticationManager: any AuthenticationManagerProtocol
    ) {
        self.networkService = networkService
        self.authenticationManager = authenticationManager
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
            let accessToken = try await authenticationManager.getValidAccessToken()
            request.setAccessToken(accessToken)
        }

        let firstAttempt = try await networkService.executeRequest(request)

        // If we get an authentication error, it could be that we erroneously
        // thought we had a valid access token (e.g the device moved to a new
        // timezone and we miscalculated its expiry date). We'll attempt a
        // single retry with a new token just in case.
        if HTTPStatusCode(rawValue: firstAttempt.1.statusCode) == .unauthorized {
            let accessToken = try await authenticationManager.refreshAccessToken()
            request.setAccessToken(accessToken)
            return try await networkService.executeRequest(request)
        } else {
            return firstAttempt
        }
    }

}
