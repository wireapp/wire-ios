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
@testable import Ziphy

typealias MockZiphyRequesterCompletionHandler = (Data?, URLResponse?, Error?) -> Void

extension NSUUID: ZiphyRequestIdentifier {}

enum MockZiphyResponse {
    case success(Data, URLResponse)
    case error(Error)
}

enum MockZiphyRequesterError: Error {
    case noResponseFound
}

/// An object that mocks performing requests to the Giphy API.
final class MockZiphyRequester: ZiphyURLRequester {
    private let networkQueue = DispatchQueue(label: "MockZiphyRequester.Network")
    private var completionHandler: MockZiphyRequesterCompletionHandler?
    private var cancellations = 0

    var response: MockZiphyResponse?

    func performZiphyRequest(
        _ request: URLRequest,
        completionHandler: @escaping MockZiphyRequesterCompletionHandler
    )
        -> ZiphyRequestIdentifier {
        self.completionHandler = completionHandler
        return NSUUID()
    }

    func cancelZiphyRequest(withRequestIdentifier requestIdentifier: ZiphyRequestIdentifier) {
        cancellations += 1
    }

    // MARK: - Mock

    /// Sends the response for the given request.
    func respond() {
        guard let response else {
            self.response = .error(MockZiphyRequesterError.noResponseFound)
            respond()
            return
        }

        guard cancellations == 0 else {
            return
        }

        guard let completionHandler else {
            return
        }

        switch response {
        case let .success(data, urlResponse):
            completionHandler(data, urlResponse, nil)
        case let .error(error):
            completionHandler(nil, nil, error)
        }
    }
}
