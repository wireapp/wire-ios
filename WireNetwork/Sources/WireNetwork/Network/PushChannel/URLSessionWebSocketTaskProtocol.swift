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

// sourcery: AutoMockable
public protocol URLSessionWebSocketTaskProtocol: Sendable {

    var isOpen: Bool { get }

    var networkInformation: String { get }

    func resume()

    func cancel(
        with closeCode: URLSessionWebSocketTask.CloseCode,
        reason: Data?
    )

    func receive(completionHandler: @escaping @Sendable (Result<URLSessionWebSocketTask.Message, any Error>) -> Void)

    func receive() async throws -> URLSessionWebSocketTask.Message

    func send(_ message: URLSessionWebSocketTask.Message) async throws

    typealias AnyError = any Error
    func sendPing(pongReceiveHandler: @escaping @Sendable (AnyError?) -> Void)

}

extension URLSessionWebSocketTask: URLSessionWebSocketTaskProtocol {

    public var isOpen: Bool {
        closeCode == .invalid
    }

    public var networkInformation: String {
        "request: \(String(describing: currentRequest)), body: \(currentRequest?.httpBodyStream), response: \(String(describing: response)), payload: \((response as? HTTPURLResponse)?.description))"
    }

}
