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
import WireFoundation

final class PushChannel: PushChannelProtocol {

    typealias Stream = AsyncThrowingStream<UpdateEventEnvelope, any Error>

    private let request: URLRequest
    private let webSocket: any WebSocketProtocol
    private let decoder = JSONDecoder()

    init(
        request: URLRequest,
        webSocket: any WebSocketProtocol
    ) {
        self.request = request
        self.webSocket = webSocket
    }

    func open() throws -> Stream {
        print("opening new push channel")
        return try webSocket.open().map { [weak self, decoder] message in
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
        print("closing push channel")
        webSocket.close()
    }

}
