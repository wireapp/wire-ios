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

final class NetworkService: NSObject {

    private let baseURL: URL
    private let serverTrustValidator: ServerTrustValidator
    private var urlSession: URLSession?
    private var webSocketsByTask = [URLSessionWebSocketTask: WebSocket]()

    init(baseURL: URL, serverTrustValidator: ServerTrustValidator) {
        self.baseURL = baseURL
        self.serverTrustValidator = serverTrustValidator
    }

    deinit {
        urlSession?.invalidateAndCancel()
    }

    func configure(with urlSession: URLSession) {
        self.urlSession = urlSession
    }

    func executeRequest(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        guard let urlSession else {
            throw NetworkServiceError.serviceNotConfigured
        }

        guard let url = request.url else {
            throw NetworkServiceError.invalidRequest
        }

        var request = request
        request.url = URL(
            string: url.absoluteString,
            relativeTo: baseURL
        )

        let (data, response) = try await urlSession.data(for: request)

        guard let httpURLResponse = response as? HTTPURLResponse else {
            throw NetworkServiceError.notAHTTPURLResponse
        }

        return (data, httpURLResponse)
    }

    func executeWebSocketRequest(_ request: URLRequest) throws -> WebSocket {
        guard let urlSession else {
            throw NetworkServiceError.serviceNotConfigured
        }

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
        webSocketsByTask[task] = webSocket
        return webSocket
    }

}

extension NetworkService: URLSessionWebSocketDelegate {

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
        webSocketsByTask[webSocketTask]?.close()
        webSocketsByTask[webSocketTask] = nil
    }

}

extension NetworkService: URLSessionTaskDelegate {

    public func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: (any Error)?
    ) {
        // NOTE: This method is not called when when using async/await APIs.
        if let error {
            print("task did complete with error: \(error)")
        } else {
            print("task did complete")
        }
    }

    public func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didReceive challenge:
        URLAuthenticationChallenge
    ) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        let protectionSpace = challenge.protectionSpace

        if protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            guard let trust = challenge.protectionSpace.serverTrust else {
                // If this is missing it is Apple breaking its API contract so crash.
                fatalError("Missing server trust")
            }

            do {
                try await serverTrustValidator.validate(trust: trust, host: protectionSpace.host)
                return (.performDefaultHandling, challenge.proposedCredential)
            } catch {
                return (.cancelAuthenticationChallenge, nil)
            }
        } else {
            return (.performDefaultHandling, challenge.proposedCredential)
        }
    }

}
