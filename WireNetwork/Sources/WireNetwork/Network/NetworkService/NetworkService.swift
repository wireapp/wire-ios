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

import WireLogging
public import Foundation

// sourcery: AutoMockable
public protocol NetworkServiceProtocol {

    func executeRequest(_ request: URLRequest) async throws -> (Data, HTTPURLResponse)

}

public final class NetworkService: NSObject, NetworkServiceProtocol {

    let baseURL: URL
    private let serverTrustValidator: ServerTrustValidator
    private var urlSession: URLSession?
    private var webSocketsByTask = [URLSessionWebSocketTask: WebSocket]()

    public init(
        baseURL: URL,
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

        self.serverTrustValidator = serverTrustValidator
    }

    deinit {
        urlSession?.invalidateAndCancel()
    }

    public func configure(with urlSession: URLSession) {
        self.urlSession = urlSession
    }

    public func executeRequest(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        guard let urlSession else {
            throw NetworkServiceError.serviceNotConfigured
        }

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
        WireLogger.network.debug("web socket task did open")
        if let request = webSocketTask.currentRequest {
            WireLogger.network.log(request)
        }
    }

    public func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
        reason: Data?
    ) {
        WireLogger.network
            .debug(
                "web socket task did close. Close code: \(closeCode), Reason: \(String(data: reason ?? Data(), encoding: .utf8) ?? "No reason")"
            )
        Task {
            await webSocketsByTask[webSocketTask]?.close()
            webSocketsByTask[webSocketTask] = nil
        }
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
            WireLogger.network.error("task did complete with error: \(error)")
        } else {
            WireLogger.network.debug("task did complete")
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
