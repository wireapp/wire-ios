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

final class PushChannel: NSObject, PushChannelProtocol {

    private let request: URLRequest
    private let minTLSVersion: TLSVersion
    private var webSocket: WebSocket?

    private lazy var urlSession: URLSession = {
        let factory = URLSessionConfigurationFactory(minTLSVersion: minTLSVersion)
        let configuration = factory.makeWebSocketSessionConfiguration()
        return URLSession(
            configuration: configuration,
            delegate: self,
            delegateQueue: nil
        )
    }()

    init(
        request: URLRequest,
        minTLSVersion: TLSVersion
    ) {
        self.request = request
        self.minTLSVersion = minTLSVersion
        super.init()
    }

    deinit {
        urlSession.invalidateAndCancel()
    }

    func open() async throws -> AsyncStream<UpdateEventEnvelope> {
        print("opening new push channel")
        let connection = urlSession.webSocketTask(with: request)
        let webSocket = WebSocket(connection: connection)
        var iterator = webSocket.makeAsyncIterator()

        self.webSocket = webSocket
        let decoder = JSONDecoder()

        return AsyncStream { [weak self] in
            do {
                guard let message = try await iterator.next() else {
                    print("web socket stream has finished")
                    return nil
                }
                switch message {
                case .data(let data):
                    print("received web socket data, decoding...")
                    let envelope = try decoder.decode(UpdateEventEnvelopeV0.self, from: data)
                    return envelope.toAPIModel()

                case .string:
                    print("received web socket string, ignoring...")
                    return nil

                @unknown default:
                    print("received web socket message, ignoring...")
                    return nil
                }
            } catch {
                print("failed to get next web socket message: \(error)")
                self?.close()
                return nil
            }
        } onCancel: { [weak self] in
            print("web socket did cancel")
            self?.close()
        }
    }

    func close() {
        guard let webSocket else { return }
        print("closing push channel")
        webSocket.close()
        self.webSocket = nil
    }

}

extension PushChannel: URLSessionWebSocketDelegate {

    func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didOpenWithProtocol protocol: String?
    ) {
        print("web socket task did open")
    }

    func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
        reason: Data?
    ) {
        close()
    }

}

extension PushChannel: URLSessionDataDelegate {

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        if let error {
            print("web socket task did complete with error: \(error)")
        } else {
            print("web socket task did complete")
        }

        close()
    }

    func urlSession(
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
            let _ = protectionSpace.serverTrust,
            true // TODO: [WPB-10450] support certificate pinning
        else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        completionHandler(.performDefaultHandling, challenge.proposedCredential)
    }

}
