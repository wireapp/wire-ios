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

// MARK: - ZiphyRequestGenerator

/// An object that generates requests to the Giphy API.

struct ZiphyRequestGenerator {
    /// The host
    let host: String

    /// Creates a request for the specified endpoint and query items, if the resulting URL is valid.

    private func makeRequest(endpoint: ZiphyEndpoint, query: [URLQueryItem]? = nil) -> ZiphyResult<URLRequest> {
        let path = "/" + ZiphyEndpoint.version + endpoint.resourcePath

        var components = URLComponents()
        components.scheme = "https"
        components.host = host
        components.path = path
        components.queryItems = query

        guard let requestURL = components.url else {
            let trailingQuery = query.flatMap { "?\($0)" } ?? ""
            let invalidURL = "https://\(host)\(path)\(trailingQuery)"
            return .failure(ZiphyError.malformedURL(invalidURL))
        }

        return .success(URLRequest(url: requestURL))
    }
}

// MARK: - V1 Requests

extension ZiphyRequestGenerator {
    /// Creates the request to fetch random images.

    func makeRandomImageRequest() -> ZiphyResult<URLRequest> {
        makeRequest(endpoint: .random)
    }

    /// Creates the request to fetch trending images.
    ///
    /// - parameter resultsLimit: The maximum number of images to fetch.
    /// - parameter offset: The number of the result page to read.

    func makeTrendingImagesRequest(resultsLimit: Int, offset: Int) -> ZiphyResult<URLRequest> {
        let queryItems = [
            URLQueryItem(name: "limit", value: String(resultsLimit)),
            URLQueryItem(name: "offset", value: String(offset)),
        ]

        return makeRequest(endpoint: .trending, query: queryItems)
    }

    /// Creates the request to search for an image by name.
    ///
    /// - parameter term: The search term.
    /// - parameter resultsLimit: The maximum number of images to fetch.
    /// - parameter offset: The number of the result page to read.

    func makeSearchRequest(term: String, resultsLimit: Int, offset: Int) -> ZiphyResult<URLRequest> {
        let queryItems = [
            URLQueryItem(name: "limit", value: String(resultsLimit)),
            URLQueryItem(name: "offset", value: String(offset)),
            URLQueryItem(name: "q", value: term),
        ]

        return makeRequest(endpoint: .search, query: queryItems)
    }
}
