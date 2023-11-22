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
import WireCoreCrypto

public protocol AcmeClientInterface {
    func getACMEDirectory() async throws -> Data
    func getACMENonce(path: String) async throws -> String
    func sendACMERequest(path: String, requestBody: Data) async throws -> ACMEResponse
}

/// This class provides ACME(Automatic Certificate Management Environment) server methods for enrolling an E2EI certificate.
public class AcmeClient: NSObject, AcmeClientInterface {

    // MARK: - Properties

    private let httpClient: HttpClient

    // MARK: - Life cycle

    public init(httpClient: HttpClient) {
        self.httpClient = httpClient
    }

    public func getACMEDirectory() async throws -> Data {

        guard let domain = BackendInfo.domain else {
            throw NetworkError.invalidRequest
        }

        let path = "https://acme.\(domain)/acme/defaultteams/directory"

        let request = ZMTransportRequest(getFromPath: path, apiVersion: 0)
        let result = try await httpClient.send(request)

        guard let data = result.rawData else {
            throw NetworkError.invalidResponse
        }

        return data

    }

    public func getACMENonce(path: String) async throws -> String {

        guard let url = URL(string: path) else {
            throw NetworkError.invalidRequest
        }
        var request = URLRequest(url: url)
        request.httpMethod = Constant.HTTPMethod.head

        let (_, response) = try await httpClient.send(request)

        guard let httpResponse = response as? HTTPURLResponse,
              let replayNonce = httpResponse.value(forHTTPHeaderField: Constant.Header.replayNonce) else {
            throw NetworkError.invalidResponse
        }

        return replayNonce

    }

    public func sendACMERequest(path: String, requestBody: Data) async throws -> ACMEResponse {
        guard let url = URL(string: path) else {
            throw NetworkError.invalidRequest
        }
        var request = URLRequest(url: url)
        request.httpMethod = Constant.HTTPMethod.post
        request.setValue(Constant.ContentType.joseJson, forHTTPHeaderField: "Content-Type")
        request.httpBody = requestBody

        let (data, response) = try await httpClient.send(request)

        guard
            let httpResponse = response as? HTTPURLResponse,
            let replayNonce = httpResponse.value(forHTTPHeaderField: Constant.Header.replayNonce),
            let location = httpResponse.value(forHTTPHeaderField: Constant.Header.location)
        else {
            throw NetworkError.invalidResponse
        }

        return ACMEResponse(nonce: replayNonce, location: location, response: data)

    }

}

private enum Constant {

    enum HTTPMethod {
        static let get = "GET"
        static let post = "POST"
        static let head = "HEAD"
    }

    enum Header {
        static let replayNonce = "Replay-Nonce"
        static let location = "location"
    }

    enum ContentType {
        static let json = "application/json"
        static let joseJson = "application/jose+json"
    }

}
