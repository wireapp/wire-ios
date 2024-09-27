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

/// An object that controls searching for GIFs

public final class ZiphySearchResultsController {
    // MARK: Lifecycle

    // MARK: - Initialization

    /// Creates a new search results controller.
    ///
    /// - parameter client: The object providing access to the Giphy API.
    /// - parameter pageSize: The maximum number of objects to display on a single page.
    /// - parameter maxImageSize: The maximum size of result images, in megabytes. Defaults to 3 MB.

    public init(client: ZiphyClient, pageSize: Int, maxImageSize: Int = 3) {
        self.client = client
        self.pageSize = pageSize
        self.maxImageSize = maxImageSize * 1024 * 1024
    }

    // MARK: Public

    public let client: ZiphyClient
    public let pageSize: Int
    public let maxImageSize: Int

    /// Asks the pagination controller to fetch more results if possible.
    /// The result block returns only the inserted images, not the current ones.
    public func fetchMoreResults(_ completion: @escaping ZiphyListRequestCallback) -> CancelableTask? {
        paginationController?.updateBlock = completion
        return paginationController?.fetchNewPage()
    }

    // MARK: - Getting Search Results

    /// Performs a search with the given term and returns the results.
    public func search(
        withTerm searchTerm: String,
        _ completion: @escaping ZiphyListRequestCallback
    ) -> CancelableTask? {
        paginationController = ZiphyPaginationController()

        paginationController?.fetchBlock = { [weak self] offset in

            guard let self else {
                return nil
            }

            return client
                .search(term: searchTerm, resultsLimit: pageSize, offset: offset) { [weak self] result in
                    self?.updatePagination(result)
                }
        }

        return fetchMoreResults(completion)
    }

    /// Get the trending images.
    public func trending(_ completion: @escaping ZiphyListRequestCallback) -> CancelableTask? {
        paginationController = ZiphyPaginationController()

        paginationController?.fetchBlock = { [weak self] offset in
            guard let self else {
                return nil
            }

            return client.fetchTrending(resultsLimit: pageSize, offset: offset) { [weak self] result in
                self?.updatePagination(result)
            }
        }

        return fetchMoreResults(completion)
    }

    // MARK: - Fetching Data

    /// Attempts to fetch the data for the image of the specified type for the given GIF post.
    public func fetchImageData(
        for ziph: Ziph,
        imageType: ZiphyImageType,
        completion: @escaping ZiphyImageDataCallback
    ) {
        guard let representation = ziph.images[imageType] else {
            client.callbackQueue.async { completion(.failure(.noSuchResource)) }
            return
        }

        client.fetchImageData(at: representation.url, onCompletion: completion)
    }

    // MARK: Internal

    var paginationController: ZiphyPaginationController?

    // MARK: Private

    // MARK: - Utilities

    /// Updates the pagination controller with the given result.
    private func updatePagination(_ result: ZiphyResult<[Ziph]>) {
        paginationController?.updatePagination(result, filter: {
            guard let size = $0.images[.downsized]?.fileSize else {
                return false
            }
            return size.rawValue < self.maxImageSize
        })
    }
}
