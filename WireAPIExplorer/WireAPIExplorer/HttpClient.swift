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
import WireAPI

class HttpClient: HTTPClient {

    let session: URLSession = URLSession(configuration: .default)

    var accessToken: String?

    func login(email: String, password: String) async throws -> String {

        let url = URL(string: "https://staging-nginz-https.zinfra.io/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = """
        { 
            "email": "\(email)",
            "password": "\(password)"
        }
        """.data(using: .utf8)

        let (data, response) = try await session.data(for: request)

        return ""
    }

    func executeRequest(_ request: HTTPRequest) async throws -> HTTPResponse {
        let baseUrl = URL(string: "https://staging-nginz-https.zinfra.io")!
        let url = URL(string: request.path, relativeTo: baseUrl)!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.stringValue
        urlRequest.httpBody = request.body
        let (data, response) = try await session.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            fatalError()
        }
        return HTTPResponse(code: httpResponse.statusCode, payload: data)
    }
}

extension HTTPRequest.Method {

    var stringValue: String {
        switch self {
        case .delete: "DELETE"
        case .get: "GET"
        case .head: "HEAD"
        case .post: "POST"
        case .put: "PUT"
        }
    }

}
