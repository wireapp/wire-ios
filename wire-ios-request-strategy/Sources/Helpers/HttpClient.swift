//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

public enum NetworkError: Error {

    case invalidRequestURL
    case invalidResponse

}

public protocol HttpClient {

    func send(_ request: ZMTransportRequest) async throws -> ZMTransportResponse

}

public class HttpClientImpl: NSObject, HttpClient {

    public func send(_ request: ZMTransportRequest) async throws -> ZMTransportResponse {
        guard let url = URL(string: request.path) else {
            throw NetworkError.invalidRequestURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.methodAsString

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        return ZMTransportResponse(httpurlResponse: httpResponse, data: data, error: nil, apiVersion: 0)
    }
}
