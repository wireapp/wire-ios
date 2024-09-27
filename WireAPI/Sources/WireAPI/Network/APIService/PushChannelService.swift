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

// MARK: - PushChannelServiceProtocol

/// A service for creating push channel connections to a specific backend.
public protocol PushChannelServiceProtocol {
    /// Create a new push channel.
    ///
    /// - Parameter request: A request for a web socket connection.
    /// - Returns: A push channel.

    func createPushChannel(_ request: URLRequest) throws -> any PushChannelProtocol
}

// MARK: - PushChannelService

/// A service for creating push channel connections to a specific backend.

public final class PushChannelService: NSObject, PushChannelServiceProtocol {
    // MARK: Lifecycle

    public init(
        backendWebSocketURL: URL,
        authenticationStorage: any AuthenticationStorage,
        minTLSVersion: TLSVersion
    ) {
        self.backendWebSocketURL = backendWebSocketURL
        self.authenticationStorage = authenticationStorage
        super.init()
        let factory = URLSessionConfigurationFactory(minTLSVersion: minTLSVersion)
        let configuration = factory.makeWebSocketSessionConfiguration()
        self.urlSession = URLSession(
            configuration: configuration,
            delegate: self,
            delegateQueue: nil
        )
    }

    init(
        backendWebSocketURL: URL,
        authenticationStorage: any AuthenticationStorage,
        urlSession: URLSession
    ) {
        self.backendWebSocketURL = backendWebSocketURL
        self.authenticationStorage = authenticationStorage
        self.urlSession = urlSession
        super.init()
    }

    deinit {
        urlSession.invalidateAndCancel()
    }

    // MARK: Public

    public func createPushChannel(_ request: URLRequest) throws -> any PushChannelProtocol {
        guard let url = request.url else {
            throw PushChannelServiceError.invalidRequest
        }

        var request = request
        request.url = URL(
            string: url.absoluteString,
            relativeTo: backendWebSocketURL
        )

        guard let accessToken = authenticationStorage.fetchAccessToken() else {
            throw PushChannelServiceError.missingAccessToken
        }

        request.setAccessToken(accessToken)

        let task = urlSession.webSocketTask(with: request)
        let webSocket = WebSocket(connection: task)
        let pushChannel = PushChannel(request: request, webSocket: webSocket)
        pushChannelsByTask[task] = pushChannel
        return pushChannel
    }

    // MARK: Private

    private let backendWebSocketURL: URL
    private let authenticationStorage: any AuthenticationStorage
    private var urlSession: URLSession!

    private var pushChannelsByTask = [URLSessionWebSocketTask: PushChannel]()
}

// MARK: URLSessionWebSocketDelegate

extension PushChannelService: URLSessionWebSocketDelegate {
    public func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didOpenWithProtocol protocol: String?
    ) {
        print("web socket task did open")
    }

    public func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
        reason: Data?
    ) {
        pushChannelsByTask[webSocketTask]?.close()
        pushChannelsByTask[webSocketTask] = nil
    }
}

// MARK: URLSessionDataDelegate

extension PushChannelService: URLSessionDataDelegate {
    public func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: (any Error)?
    ) {
        // When does this get called? My guess is that it's for the initial request.
        if let error {
            print("web socket task did complete with error: \(error)")
        } else {
            print("web socket task did complete")
        }
    }

    public func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        print("web socket task did receive challenge")

        let protectionSpace = challenge.protectionSpace

        guard protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust else {
            completionHandler(.performDefaultHandling, challenge.proposedCredential)
            return
        }

        guard
            protectionSpace.serverTrust != nil,
            true // TODO: [WPB-10450] support certificate pinning
        else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        completionHandler(.performDefaultHandling, challenge.proposedCredential)
    }
}
