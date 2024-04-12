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

/// An object responsible for facilitating the iteration of
/// one or more pages returned from an api endpoint.

struct PayloadPager<Payload>: AsyncSequence {

    typealias Element = [Payload]
    typealias PageFetcher = (String) async throws -> Page
    typealias Page = (Element, hasMore: Bool, nextStart: String)

    let fetchPage: PageFetcher

    func makeAsyncIterator() -> Iterator {
        return Iterator(
            start: "",
            fetchPage: fetchPage
        )
    }

    struct Iterator: AsyncIteratorProtocol {

        private var start: String
        private var hasMore = true
        private let fetchPage: PageFetcher

        init(
            start: String,
            fetchPage: @escaping PageFetcher
        ) {
            self.start = start
            self.fetchPage = fetchPage
        }

        mutating func next() async throws -> [Payload]? {
            guard hasMore else { return nil }
            let (payloads, hasMore, nextStart) = try await fetchPage(start)
            self.hasMore = hasMore
            self.start = nextStart
            return payloads
        }
    }

}
