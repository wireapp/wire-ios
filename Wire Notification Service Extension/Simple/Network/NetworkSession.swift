//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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
import WireTransport

@available(iOS 15, *)
final class NetworkSession: NSObject, URLSessionTaskDelegate, Loggable {

    // MARK: - Types

    enum NetworkError: Error {

        case invalidResponse
        case invalidRequestURL

    }

    // MARK: - Properties

    var accessToken: AccessToken?

    private let urlSession = URLSession(configuration: .ephemeral)
    private let cookieStorage: ZMPersistentCookieStorage
    private let environment: BackendEnvironmentProvider = BackendEnvironment.shared

    // MARK: - Life cycle

    init(userID: UUID) throws {
        guard let serverName = environment.backendURL.host else {
            throw NotificationServiceError.invalidEnvironment
        }

        cookieStorage = ZMPersistentCookieStorage(
            forServerName: serverName,
            userIdentifier: userID
        )

        super.init()
    }

    // MARK: - Methods

    var isAuthenticated: Bool {
        return cookieStorage.isAuthenticated
    }

    func execute<E: Endpoint>(endpoint: E) async throws -> E.Result {
        logger.trace("executing endpoint: \(String(describing: endpoint))")
        let response = try await send(request: endpoint.request)
        // TODO: Check the headers
        return endpoint.parseResponse(response)
    }

    func send(request: NetworkRequest) async throws -> NetworkResponse {
        logger.trace("sending request: \(String(describing: request))")
        guard let url = URL(string: request.path, relativeTo: environment.backendURL) else {
            throw NetworkError.invalidRequestURL
        }

        let urlRequest = NSMutableURLRequest(url: url)
        urlRequest.httpMethod = request.httpMethod.rawValue
        urlRequest.addValue(request.contentType.rawValue, forHTTPHeaderField: "Content-Type")
        urlRequest.addValue(request.acceptType.rawValue, forHTTPHeaderField: "Accept")

        cookieStorage.setRequestHeaderFieldsOn(urlRequest)

        if let accessToken = accessToken {
            urlRequest.addValue(accessToken.headerValue, forHTTPHeaderField: "Authorization")
        }

        logger.info("sending network request: \(urlRequest)")

        let (data, response) = try await urlSession.data(
            for: urlRequest as URLRequest,
            delegate: self
        )

        if let jsonPayload = String(data: data, encoding: .utf8) {
            logger.info("received response payload for request \(request.path): \(jsonPayload)")
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
            logger.info("received error response: \(String(describing: errorResponse))")
            return .failure(errorResponse)
        } else {
            let successResponse = SuccessResponse(
                status: httpResponse.statusCode,
                data: data
            )

            logger.info("received success response: \(String(describing: successResponse))")
            return .success(successResponse)
        }
    }

}

extension AccessToken {

    var headerValue: String {
        return "\(type) \(token)"
    }

}
