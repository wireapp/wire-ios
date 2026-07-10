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

import Foundation
import WireLogging

final class NetworkServiceSessionDelegate: NSObject, URLSessionWebSocketDelegate, URLSessionTaskDelegate, Sendable {

    private let serverTrustValidator: ServerTrustValidator
    private let webSocketStore: WebSocketStore

    init(
        serverTrustValidator: ServerTrustValidator,
        webSocketStore: WebSocketStore
    ) {
        self.serverTrustValidator = serverTrustValidator
        self.webSocketStore = webSocketStore
        super.init()
    }

    // MARK: - URLSessionWebSocketDelegate

    func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didOpenWithProtocol protocol: String?
    ) {
        WireLogger.network.debug("web socket task did open")
        if let request = webSocketTask.currentRequest {
            WireLogger.network.log(request)
        }
    }

    func urlSession(
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
            await webSocketStore.retrieve(for: webSocketTask)?.close()
            await webSocketStore.remove(for: webSocketTask)
        }
    }

    // MARK: - URLSessionTaskDelegate

    func urlSession(
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

    func urlSession(
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
