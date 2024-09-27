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

/// A block that repeats a previous request, but moves to the given resource offset.
typealias ZiphyPaginatedFetchBlock = (_ offset: Int) -> CancelableTask?

// MARK: - ZiphyPaginationController

/// An object that handles pagination of Giphy requests.

final class ZiphyPaginationController {
    var ziphs: [Ziph] = []
    var offset = 0
    var isAtEnd = false

    /// The block that fetches the paginated resource when needed.
    var fetchBlock: ZiphyPaginatedFetchBlock?

    /// The block that is called when the paginated data changes.
    var updateBlock: ZiphyListRequestCallback?

    // MARK: - Interacting with the Data

    /// Fetches a new page from the current offset.
    func fetchNewPage() -> CancelableTask? {
        fetchNewPage(offset)
    }

    // MARK: - Updating the Data

    private func fetchNewPage(_ offset: Int) -> CancelableTask? {
        guard !isAtEnd else {
            return nil
        }

        return fetchBlock?(offset)
    }

    func updatePagination(_ result: ZiphyResult<[Ziph]>, filter: ((Ziph) -> Bool)?) {
        switch result {
        case let .success(insertedZiphs):
            let newItems = insertedZiphs.filter { filter?($0) ?? true }
            ziphs.append(contentsOf: newItems)
            offset = ziphs.count
            updateBlock?(.success(newItems))

        case let .failure(error):
            if case .noMorePages = error {
                isAtEnd = true
            }

            updateBlock?(.failure(error))
        }
    }
}
