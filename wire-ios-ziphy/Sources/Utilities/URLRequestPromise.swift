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

/// A block of code executed when a URL request fails.
///
/// - parameter error: The error that prevented the request from succeeding.

typealias URLRequestSuccessFailureHandler = (_ error: ZiphyError) -> Void

/// A block of code executed when a URL request completes with success.
///
/// If you throw an error from its body, it will marked the promise as failed and
/// will trigger its failure handler.
///
/// - parameter data: The body of the response as returned by the server.

typealias URLRequestSuccessHandler = (_ data: Data) throws -> Void

/// An object that handles the asynchronous delivery of a network response.
///
/// If you set the `requestIdentifier` property, the promise becomes eligible for cancellation.
///
/// Use the `failureHandler` to handle network failure. Use the `successHandler` to parse the
/// data from the response.
///
/// To force failure, call `rejectWithError:`. This will trigger the `failureHandler`. Calling `cancel`
/// fails sliently.

final class URLRequestPromise: CancelableTask {
    let requester: ZiphyURLRequester

    /// The unique identifier of the request in the requester. You need to
    /// set this value manually after you schedule the request if you want to
    /// support cancellation.
    var requestIdentifier: ZiphyRequestIdentifier?

    /// The block that will be executed in case the operation succeeds,
    /// in the order they were added with the `then` function.
    var successHandler: URLRequestSuccessHandler? {
        didSet {
            if let result = self.result, isResolved == true, isCancelled == false {
                notifyResult(result.0, result.1, result.2).map(handleErrorIfNeeded)
            }
        }
    }

    /// The block that will be executed in case the operation fails.
    var failureHandler: URLRequestSuccessFailureHandler? {
        didSet {
            if let error = self.failureError, isResolved == true, isCancelled == false {
                failureHandler?(error)
            }
        }
    }

    private var isCancelled = false
    private var isResolved = false
    private var result: (Data?, URLResponse?, Error?)?
    private var failureError: ZiphyError?

    /// Creates a new promise for a request, before it is scheduled.
    ///
    /// - parameter requester: The object that will perform the request whose
    /// result is represented by this promise.

    init(requester: ZiphyURLRequester) {
        self.requester = requester
    }

    // MARK: - Response Handling

    /// Provides the raw result of the response.
    ///
    /// This method will check for errors in the error parameter and the structure
    /// of the response. In case it finds an error, the `failureHandler` will be called.
    /// If the response is valid, it will call the `successHandler`.
    ///
    /// - parameter data: The data returned by the server.
    /// - parameter response: The response provided by the server.
    /// - parameter error: The error provided by the system in case the request could not
    /// be scheduled or performed correctly.

    func resolve(_ data: Data?, _ response: URLResponse?, _ error: Error?) {
        guard !isCancelled, !isResolved else {
            return
        }

        notifyResult(data, response, error).map(handleErrorIfNeeded)
        result = (data, response, error)
        isResolved = true
    }

    /// Cancels the network request if possible.
    ///
    /// The network request will only be cancelled if you set the `requestIdentifier` property
    /// when starting the request.
    ///
    /// If you already cancelled the request, nothing happens.

    func cancel() {
        guard !isCancelled else {
            return
        }

        requestIdentifier.map(requester.cancelZiphyRequest)
        isCancelled = true
    }

    // MARK: - Utilities

    private func notifyResult(_ data: Data?, _: URLResponse?, _ error: Error?) -> ZiphyError? {
        if let networkError = error {
            return .networkError(networkError)
        }

        guard let data else {
            return .badResponse("No data was returned by the server.")
        }

        do {
            try successHandler?(data)
        } catch {
            return ZiphyError(error)
        }

        return nil
    }

    private func handleErrorIfNeeded(_ error: ZiphyError?) {
        guard let error else {
            return
        }

        self.failureError = error
        failureHandler?(error)
    }
}
