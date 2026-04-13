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

import WireLogging

// sourcery: AutoMockable
public protocol NetworkServiceProtocol: Sendable {

    func executeRequest(_ request: URLRequest) async throws -> (Data, HTTPURLResponse)

}

public final class NetworkService: NetworkServiceProtocol {

    let baseURL: URL

    private let urlSession: URLSession
    private let webSocketStore: WebSocketStore

    public init(
        baseURL: URL,
        urlSessionConfiguration configuration: URLSessionConfiguration,
        serverTrustValidator: ServerTrustValidator
    ) {
        // Make sure the base url is a directory path,
        // i.e www.wire.com -> www.wire.com/ and
        // www.wire.com/staging -> www.wire.com/staging/
        // This is important when we resolve relative paths on top
        // of this base url because if the base is not considered a
        // directory then the path will be replaced by the relative path
        // (e.g www.wire.com/staging + foo -> www.wire.com/foo) rather than
        // concatenated (e.g www.wire.com/staging/foo).
        if !baseURL.path().isEmpty, !baseURL.hasDirectoryPath {
            let lastComponent = baseURL.lastPathComponent
            self.baseURL = baseURL.deletingLastPathComponent().appending(
                path: lastComponent,
                directoryHint: .isDirectory
            )
        } else {
            self.baseURL = baseURL
        }

        let webSocketStore = WebSocketStore()
        self.webSocketStore = webSocketStore

        let delegate = NetworkServiceSessionDelegate(
            serverTrustValidator: serverTrustValidator,
            webSocketStore: webSocketStore
        )
        self.urlSession = URLSession(configuration: configuration, delegate: delegate, delegateQueue: .none)
    }

    deinit {
        urlSession.invalidateAndCancel()
    }

    public func executeRequest(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        guard let url = request.url else {
            throw NetworkServiceError.invalidRequest
        }

        // To properly concatenate this URL to the base (which should be
        // a directory), we must remove the leading slash.
        var urlString = url.absoluteString
        urlString = String(urlString.drop(while: { $0 == "/" }))

        var request = request
        request.url = URL(
            string: urlString,
            relativeTo: baseURL
        )

        WireLogger.network.log(request)
        let (data, response) = try await urlSession.data(for: request)

        guard let httpURLResponse = response as? HTTPURLResponse else {
            throw NetworkServiceError.notAHTTPURLResponse
        }
        WireLogger.network.log(response: httpURLResponse, body: data)

        return (data, httpURLResponse)
    }

    func executeWebSocketRequest(_ request: URLRequest) async throws -> WebSocket {
        guard let url = request.url else {
            throw NetworkServiceError.invalidRequest
        }

        var request = request
        request.url = URL(
            string: url.absoluteString,
            relativeTo: baseURL
        )

        let task = urlSession.webSocketTask(with: request)
        let webSocket = WebSocket(connection: task)
        await webSocketStore.store(webSocket, for: task)
        return webSocket
    }

}
