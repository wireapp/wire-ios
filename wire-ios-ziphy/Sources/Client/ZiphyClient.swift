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

/// A block that will be executed with the result of a Ziph list fetch request.
public typealias ZiphyListRequestCallback = (ZiphyResult<[Ziph]>) -> Void

/// A block that will be executed with the result of a single Ziph lookup request.
public typealias ZiphyLookupCallback = (ZiphyResult<Ziph>) -> Void

/// A block that will be executed with the result of an image data fetch request.
public typealias ZiphyImageDataCallback = (ZiphyResult<Data>) -> Void

/// An object that provides access to the Giphy API.

public final class ZiphyClient {
    let host: String
    let requester: ZiphyURLRequester
    let downloadSession: ZiphyURLRequester
    let requestGenerator: ZiphyRequestGenerator
    let callbackQueue: DispatchQueue

    /// Creates a Giphy API client.
    /// 
    /// - parameter host: The host that provides the REST API for Giphy.
    /// - parameter requester: The object that will send and process the requests to the API.
    /// - parameter downloadSession: The requester to use to download images.
    /// - parameter callbackQueue: The queue where completion handlers will be called.

    public init(
        host: String,
        requester: ZiphyURLRequester,
        downloadSession: ZiphyURLRequester,
        callbackQueue: DispatchQueue = .main
    ) {
        self.requester = requester
        self.host = host
        self.callbackQueue = callbackQueue
        self.downloadSession = downloadSession
        self.requestGenerator = ZiphyRequestGenerator(host: host)
    }
}

// MARK: - List Requests

extension ZiphyClient {
    /// Attempts to fetch the list of trending GIF images.
    /// 
    /// - paraneter resultsLimit: The maximum number of images to fetch per page.
    /// - parameter offset: The offset of the first image to fetch.
    /// - parameter onCompletion: The block of code to execute with the result of the fetch.
    /// 
    /// - returns: The cancellable fetch task.

    @discardableResult
    public func fetchTrending(
        resultsLimit: Int = 25,
        offset: Int,
        onCompletion: @escaping ZiphyListRequestCallback
    ) -> CancelableTask? {
        let request = requestGenerator.makeTrendingImagesRequest(resultsLimit: resultsLimit, offset: offset)
        return performPotentialZiphListRequest(request, onCompletion: onCompletion)
    }

    /// Attempts to search for GIF images that match the given query.
    /// 
    /// - parameter term: The search query to execute.
    /// - paraneter resultsLimit: The maximum number of images to fetch per page.
    /// - parameter offset: The offset of the first image to fetch.
    /// - parameter onCompletion: The block of code to execute with the result of the fetch.
    /// 
    /// - returns: The cancellable fetch task.

    @discardableResult
    public func search(
        term: String,
        resultsLimit: Int = 25,
        offset: Int = 0,
        onCompletion: @escaping ZiphyListRequestCallback
    ) -> CancelableTask? {
        let request = requestGenerator.makeSearchRequest(term: term, resultsLimit: resultsLimit, offset: offset)
        return performPotentialZiphListRequest(request, onCompletion: onCompletion)
    }

    private func performPotentialZiphListRequest(
        _ potentialRequest: ZiphyResult<URLRequest>,
        isPaginated: Bool = true,
        onCompletion: @escaping ZiphyListRequestCallback
    ) -> CancelableTask? {
        let completionHandler = makeCompletionHandler(onCompletion)
        let listTask = performDataTask(potentialRequest, errorHandler: completionHandler)

        listTask?.failureHandler = {
            completionHandler(.failure($0))
        }

        listTask?.successHandler = {
            let imageList: [Ziph] = if isPaginated {
                try self.decodePaginatedResponse($0)
            } else {
                try self.decodeDataResponse($0)
            }

            completionHandler(.success(imageList))
        }

        return listTask
    }
}

// MARK: - Resource Requests

extension ZiphyClient {
    /// Attempts to fetch a random GIF image post.
    /// 
    /// - parameter callbackQueue: The queue where the callback should be executed. Defaults
    /// to the main queue.
    /// - parameter onCompletion: The block of code to execute with the result of the fetch.
    /// 
    /// - returns: The cancellable fetch task.

    @discardableResult
    public func fetchRandomPost(onCompletion: @escaping ZiphyLookupCallback) -> CancelableTask? {
        let request = requestGenerator.makeRandomImageRequest()

        let completionHandler = makeCompletionHandler(onCompletion)
        let dataTask = performDataTask(request, errorHandler: completionHandler)

        dataTask?.failureHandler = {
            completionHandler(.failure($0))
        }

        dataTask?.successHandler = {
            let ziph: Ziph = try self.decodeDataResponse($0)
            completionHandler(.success(ziph))
        }

        return dataTask
    }

    /// Attempts to fetch the animated image representation for the given GIF.
    /// 
    /// - parameter url: The remote URL of image to fetch.
    /// - parameter callbackQueue: The queue where the callback should be executed. Defaults
    /// to the main queue.
    /// - parameter onCompletion: The block of code to execute with the result of the fetch.
    /// 
    /// - returns: The cancellable fetch task.

    @discardableResult
    public func fetchImageData(at url: URL, onCompletion: @escaping ZiphyImageDataCallback) -> CancelableTask? {
        let completionHandler = makeCompletionHandler(onCompletion)
        let request = URLRequest(url: url)
        let downloadTask = performDataTask(request, requester: downloadSession)

        downloadTask.failureHandler = {
            completionHandler(.failure($0))
        }

        downloadTask.successHandler = {
            completionHandler(.success($0))
        }

        return downloadTask
    }
}

// MARK: - Utilities

extension ZiphyClient {
    /// Creates a wrapper around a completion handler that calls it on the specified queue.
    private func makeCompletionHandler<T>(_ onCompletion: @escaping (T) -> Void) -> (T) -> Void {
        { value in
            self.callbackQueue.async {
                onCompletion(value)
            }
        }
    }

    /// Performs a data task if the URL request is available, or calls the error otherwise.
    private func performDataTask<T>(
        _ potentialRequest: ZiphyResult<URLRequest>,
        errorHandler: (ZiphyResult<T>) -> Void
    ) -> URLRequestPromise? {
        switch potentialRequest {
        case let .failure(error):
            errorHandler(.failure(error))
            return nil

        case let .success(request):
            return performDataTask(request, requester: requester)
        }
    }

    /// Creates and schedules a request for the given URL request and returns the promise to its reponse.
    private func performDataTask(_ request: URLRequest, requester: ZiphyURLRequester) -> URLRequestPromise {
        let promise = URLRequestPromise(requester: requester)
        let requestIdentifier = requester.performZiphyRequest(request, completionHandler: promise.resolve)

        promise.requestIdentifier = requestIdentifier
        return promise
    }

    /// Decodes a paginated response.
    private func decodePaginatedResponse<ZiphyData>(_ data: Data) throws -> ZiphyData where ZiphyData: Codable {
        let response: ZiphyPaginatedResponse<ZiphyData>

        do {
            let decoder = JSONDecoder()
            response = try decoder.decode(ZiphyPaginatedResponse<ZiphyData>.self, from: data)
        } catch {
            throw ZiphyError.jsonSerialization(error)
        }

        let pagination = response.pagination

        if pagination.offset >= pagination.totalCount {
            throw ZiphyError.noMorePages
        }

        return response.data
    }

    /// Decodes a response for a single resource.
    private func decodeDataResponse<ZiphyData>(_ data: Data) throws -> ZiphyData where ZiphyData: Codable {
        do {
            let decoder = JSONDecoder()
            let response = try decoder.decode(ZiphyDataResponse<ZiphyData>.self, from: data)
            return response.data
        } catch {
            throw ZiphyError.jsonSerialization(error)
        }
    }
}
