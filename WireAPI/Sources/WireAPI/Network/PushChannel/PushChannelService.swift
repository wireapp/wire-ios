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

/// A service for creating push channel connections to a specific backend.
public protocol PushChannelServiceProtocol {

    /// Create a new push channel.
    ///
    /// - Parameter request: A request for a web socket connection.
    /// - Returns: A push channel.

    func createPushChannel(_ request: URLRequest) throws -> any PushChannelProtocol

}

/// A service for creating push channel connections to a specific backend.

public final class PushChannelService: PushChannelServiceProtocol {

    private let networkService: NetworkService
    private let authenticationStorage: any AuthenticationStorage

    public convenience init(
        backendWebSocketURL: URL,
        authenticationStorage: any AuthenticationStorage,
        minTLSVersion: TLSVersion
    ) {
        let factory = URLSessionConfigurationFactory(minTLSVersion: minTLSVersion)
        let configuration = factory.makeWebSocketSessionConfiguration()
        let networkService = NetworkService(baseURL: backendWebSocketURL)
        let urlSession = URLSession(
            configuration: configuration,
            delegate: networkService,
            delegateQueue: nil
        )
        networkService.configure(with: urlSession)

        self.init(
            networkService: networkService,
            authenticationStorage: authenticationStorage
        )
    }

    init(
        networkService: NetworkService,
        authenticationStorage: any AuthenticationStorage
    ) {
        self.networkService = networkService
        self.authenticationStorage = authenticationStorage
    }

    public func createPushChannel(_ request: URLRequest) throws -> any PushChannelProtocol {
        var request = request

        guard let accessToken = authenticationStorage.fetchAccessToken() else {
            throw PushChannelServiceError.missingAccessToken
        }

        request.setAccessToken(accessToken)
        let webSocket = try networkService.executeWebSocketRequest(request)
        return PushChannel(webSocket: webSocket)
    }

}
