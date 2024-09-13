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

enum MockPaginatedResponse {
    case success([Ziph])
    case error(Error)
}

final class MockPaginatedRequester: ZiphyURLRequester {
    private let networkQueue = DispatchQueue(label: "MockZiphyRequester.Network")
    private var completionHandler: MockZiphyRequesterCompletionHandler?
    private var cancellations = 0

    private var offset = 0
    private var limit = 0
    private var url: URL?

    var response: MockPaginatedResponse?

    func performZiphyRequest(
        _ request: URLRequest,
        completionHandler: @escaping MockZiphyRequesterCompletionHandler
    )
        -> ZiphyRequestIdentifier {
        self.completionHandler = completionHandler
        url = request.url

        if let urlComponents = URLComponents(url: request.url!, resolvingAgainstBaseURL: false) {
            if let offsetItem = urlComponents.queryItems?.first(where: { $0.name == "offset" }) {
                offset = offsetItem.value.flatMap(Int.init) ?? 0
            }

            if let limitItem = urlComponents.queryItems?.first(where: { $0.name == "limit" }) {
                limit = limitItem.value.flatMap(Int.init) ?? 0
            }
        }

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
        case let .success(ziphs):

            let paginatedResponse: ZiphyPaginatedResponse<[Ziph]>

            if offset >= ziphs.endIndex {
                let pagination = ZiphyPagination(count: 0, totalCount: ziphs.count, offset: offset)
                paginatedResponse = ZiphyPaginatedResponse<[Ziph]>(pagination: pagination, data: [])
            } else {
                let slice = ziphs.suffix(from: offset).prefix(limit)
                let pagination = ZiphyPagination(count: slice.count, totalCount: ziphs.count, offset: offset)
                paginatedResponse = ZiphyPaginatedResponse<[Ziph]>(pagination: pagination, data: Array(slice))
            }

            let paginatedData = try! JSONEncoder().encode(paginatedResponse)
            let successResponse = HTTPURLResponse(
                url: url!,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: nil
            )
            completionHandler(paginatedData, successResponse, nil)

        case let .error(error):
            completionHandler(nil, nil, error)
        }
    }
}
