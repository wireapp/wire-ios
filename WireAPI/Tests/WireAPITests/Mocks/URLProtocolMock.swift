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

/// An object that facilitates mocking url requests and responses.

final class URLProtocolMock: URLProtocol {

    static var mockHandler: ((URLRequest) throws -> (Data?, URLResponse))?

    override static func canInit(with request: URLRequest) -> Bool {
        // This protocol can handle the request.
        true
    }

    override static func canonicalRequest(for request: URLRequest) -> URLRequest {
        // Let the request simply pass through.
        request
    }

    override func startLoading() {
        guard let mockHandler = Self.mockHandler else {
            fatalError("no mock handler for `URLProtocolMock`")
        }

        let data: Data?
        let response: URLResponse

        do {
            (data, response) = try mockHandler(request)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }

        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)

        if let data {
            client?.urlProtocol(self, didLoad: data)
        }

        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {
        // The request was cancelled or completed.
    }

}
