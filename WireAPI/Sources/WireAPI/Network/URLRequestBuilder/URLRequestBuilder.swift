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

// MARK: - URLRequestBuilder

struct URLRequestBuilder {
    private var request: URLRequest

    init(path: String) throws {
        guard let url = URL(string: path) else {
            throw URLRequestBuilderError.invalidPath(path)
        }

        self.init(url: url)
    }

    init(url: URL) {
        self.request = URLRequest(url: url)
    }

    func build() -> URLRequest {
        request
    }

    func withMethod(_ method: HTTPMethod) -> Self {
        withCopy {
            $0.request.httpMethod = method.rawValue
        }
    }

    func withBody(
        _ body: Data,
        contentType: HTTPContentType
    ) -> Self {
        withCopy {
            $0.request.httpBody = body
            $0.request.setValue(
                contentType.rawValue,
                forHTTPHeaderField: "Content-Type"
            )
        }
    }

    func withAcceptType(_ contentType: HTTPContentType) -> Self {
        withCopy {
            $0.request.setValue(
                contentType.rawValue,
                forHTTPHeaderField: "Accept"
            )
        }
    }

    private func withCopy(_ mutation: (inout Self) -> Void) -> Self {
        var copy = self
        mutation(&copy)
        return copy
    }
}

extension URLRequestBuilder {
    func postJSONPayload(
        _ payload: some Encodable,
        encoder: JSONEncoder = .defaultEncoder
    ) throws -> Self {
        try withMethod(.post).withBody(
            encoder.encode(payload),
            contentType: .json
        )
    }
}
