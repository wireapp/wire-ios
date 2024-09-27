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

/// Iterate through one or more pages returned from
/// an api endpoint.

public struct PayloadPager<Payload>: AsyncSequence {
    // MARK: Lifecycle

    public init(
        start: String? = nil,
        fetchPage: @escaping PageFetcher
    ) {
        self.start = start
        self.fetchPage = fetchPage
    }

    // MARK: Public

    public typealias Element = [Payload]
    public typealias PageFetcher = (String?) async throws -> Page

    public struct Page {
        // MARK: Lifecycle

        public init(
            element: Element,
            hasMore: Bool,
            nextStart: String
        ) {
            self.element = element
            self.hasMore = hasMore
            self.nextStart = nextStart
        }

        // MARK: Public

        public let element: Element
        public let hasMore: Bool
        public let nextStart: String
    }

    public struct Iterator: AsyncIteratorProtocol {
        // MARK: Lifecycle

        init(
            start: String?,
            fetchPage: @escaping PageFetcher
        ) {
            self.start = start
            self.fetchPage = fetchPage
        }

        // MARK: Public

        public mutating func next() async throws -> [Payload]? {
            guard hasMore else {
                return nil
            }
            let page = try await fetchPage(start)
            hasMore = page.hasMore
            start = page.nextStart
            return page.element
        }

        // MARK: Private

        private var start: String?
        private var hasMore = true
        private let fetchPage: PageFetcher
    }

    public func makeAsyncIterator() -> Iterator {
        Iterator(
            start: start,
            fetchPage: fetchPage
        )
    }

    // MARK: Internal

    var start: String?
    let fetchPage: PageFetcher
}
