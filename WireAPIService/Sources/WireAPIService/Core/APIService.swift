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

public protocol APIServiceProtocol {
    func getBackendInfoAPI(for version: APIVersion) async throws -> BackendInfoModel
}

public struct APIService: APIServiceProtocol {

    private let host = "wire.com"
    private let urlSession = URLSession.shared

    init() { }

    func request(_ endpoint: Endpoint) async throws -> Data {
        let urlRequest = try makeURLRequest(for: endpoint)
        return try await request(urlRequest)
    }

    func request(_ request: URLRequest) async throws -> Data {
        let result: (data: Data, response: URLResponse)
        do {
            result = try await urlSession.data(for: request)
        } catch {
            throw APIServiceError.urlSessionError(error)
        }

        guard let httpResponse = result.response as? HTTPURLResponse else {
            throw APIServiceError.noHTTPURLResponse
        }

        switch httpResponse.statusCode {
        case 200..<400:
            return result.data
        default:
            throw APIServiceError.serverError(httpStatusCode: httpResponse.statusCode)
        }
    }

    func makeURLRequest(for endpoint: Endpoint) throws -> URLRequest {
        guard let url = endpoint.makeURL(with: host) else {
            throw APIServiceError.urlRequestInvalid
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.httpBody = endpoint.body
        // request.allHTTPHeaderFields could be used for endpoint specific http headers

        return request
    }
}
