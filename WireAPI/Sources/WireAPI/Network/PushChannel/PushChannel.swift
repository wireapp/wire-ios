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
    private var webSocket: (any WebSocketProtocol)?
    private var webSocketProvider: (any WebSocketProvider)!

    init(
        request: URLRequest,
        minTLSVersion: TLSVersion
    ) {
        self.request = request
        super.init()
        let factory = URLSessionConfigurationFactory(minTLSVersion: minTLSVersion)
        let configuration = factory.makeWebSocketSessionConfiguration()
        webSocketProvider = URLSession(
            configuration: configuration,
            delegate: self,
            delegateQueue: nil
        )
    }

    init(
        request: URLRequest,
        webSocketProvider: any WebSocketProvider
    ) {
        self.request = request
        self.webSocketProvider = webSocketProvider
    }

    deinit {
        webSocketProvider.tearDown()
    }

    func open() async throws -> AsyncThrowingStream<UpdateEventEnvelope, Error> {
        print("opening new push channel")
        let webSocket = webSocketProvider.makeWebSocket(with: request)
        self.webSocket = webSocket
        let decoder = JSONDecoder()

        return webSocket.makeStream().map { [weak self] message in
            do {
                switch message {
                case .data(let data):
                    print("received web socket data, decoding...")
                    let envelope = try decoder.decode(UpdateEventEnvelopeV0.self, from: data)
                    return envelope.toAPIModel()

                case .string:
                    print("received web socket string, ignoring...")
                    throw PushChannelError.receivedInvalidMessage

                @unknown default:
                    print("received web socket message, ignoring...")
                    throw PushChannelError.receivedInvalidMessage
                }
            } catch {
                print("failed to get next web socket message: \(error)")
                self?.close()
                throw error
            }
        }.toStream()
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

extension AsyncSequence {

    func toStream() -> AsyncThrowingStream<Element, Error> {
        var iterator = makeAsyncIterator()
        return AsyncThrowingStream {
            try await iterator.next()
        }
    }

}
