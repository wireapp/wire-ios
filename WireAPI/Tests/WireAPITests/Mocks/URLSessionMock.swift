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

@testable import WireAPI

final class URLSessionMock: URLSessionProtocol {

    var receivedRequests = [URLRequest]()
    var mockResponse: ((URLRequest) async throws -> (Data, URLResponse))?

    func data(
        for request: URLRequest,
        delegate: (any URLSessionTaskDelegate)? = nil
    ) async throws -> (Data, URLResponse) {
        receivedRequests.append(request)

        guard let mockResponse else {
            throw "URLSessionMock has no mock response"
        }

        return try await mockResponse(request)
    }

    var webSocket: WebSocket?

    func webSocket(with request: URLRequest) -> WebSocket {
        guard let webSocket else {
            fatalError("URLSessionMock has no webSocket")
        }

        return webSocket
    }

    func invalidateAndCancel() {
        
    }

}
