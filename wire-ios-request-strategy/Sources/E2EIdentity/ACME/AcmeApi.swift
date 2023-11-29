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

public protocol AcmeApiInterface {
    func getACMEDirectory() async throws -> Data
    func getACMENonce(path: String) async throws -> String
    func sendACMERequest(path: String, requestBody: Data) async throws -> ACMEResponse
    func sendChallengeRequest(path: String, requestBody: Data) async throws -> ChallengeResponse
}

/// This class provides ACME(Automatic Certificate Management Environment) server methods for enrolling an E2EI certificate.
public class AcmeApi: NSObject, AcmeApiInterface {

    // MARK: - Properties

    private let httpClient: HttpClientCustom

    // MARK: - Life cycle

    public init(httpClient: HttpClientCustom) {
        self.httpClient = httpClient
    }

    public func getACMEDirectory() async throws -> Data {

        guard let domain = BackendInfo.domain else {
            throw NetworkError.errorEncodingRequest
        }

        let path = "https://acme.\(domain)/acme/defaultteams/directory"

        guard let url = URL(string: path) else {
            throw NetworkError.errorEncodingRequest
        }
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.get
        let (data, _) = try await httpClient.send(request)

        return data

    }

    public func getACMENonce(path: String) async throws -> String {

        guard let url = URL(string: path) else {
            throw NetworkError.errorEncodingRequest
        }
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.head

        let (_, response) = try await httpClient.send(request)

        guard let httpResponse = response as? HTTPURLResponse,
              let replayNonce = httpResponse.value(forHTTPHeaderField: HeaderKey.replayNonce) else {
            throw NetworkError.errorDecodingResponseNew(response)
        }

        return replayNonce

    }

    public func sendACMERequest(path: String, requestBody: Data) async throws -> ACMEResponse {
        guard let url = URL(string: path) else {
            throw NetworkError.errorEncodingRequest
        }
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.post
        request.setValue(ContentType.joseJson, forHTTPHeaderField: "Content-Type")
        request.httpBody = requestBody

        let (data, response) = try await httpClient.send(request)

        guard
            let httpResponse = response as? HTTPURLResponse,
            let replayNonce = httpResponse.value(forHTTPHeaderField: HeaderKey.replayNonce),
            let location = httpResponse.value(forHTTPHeaderField: HeaderKey.location)
        else {
            throw NetworkError.errorDecodingResponseNew(response)
        }

        return ACMEResponse(nonce: replayNonce, location: location, response: data)

    }

    public func sendChallengeRequest(path: String, requestBody: Data) async throws -> ChallengeResponse {
        guard let url = URL(string: path) else {
            throw NetworkError.errorEncodingRequest
        }
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.post
        request.setValue(ContentType.joseJson, forHTTPHeaderField: "Content-Type")
        request.httpBody = requestBody

        let (data, response) = try await httpClient.send(request)

        guard
            let httpResponse = response as? HTTPURLResponse,
            let replayNonce = httpResponse.value(forHTTPHeaderField: HeaderKey.replayNonce),
            let challengeResponse = ChallengeResponse(data)
        else {
            throw NetworkError.errorDecodingResponseNew(response)
        }

        return ChallengeResponse(type: challengeResponse.type,
                                 url: challengeResponse.url,
                                 status: challengeResponse.status,
                                 token: challengeResponse.token,
                                 nonce: replayNonce)

    }

}

enum HTTPMethod {
    static let get = "GET"
    static let post = "POST"
    static let head = "HEAD"
}

enum HeaderKey {
    static let replayNonce = "Replay-Nonce"
    static let location = "location"
}

enum ContentType {
    static let json = "application/json"
    static let joseJson = "application/jose+json"
}

public protocol HttpClientCustom {

    func send(_ request: URLRequest) async throws -> (Data, URLResponse)

}

public class HttpClientE2EI: NSObject, HttpClientCustom {

    public func send(_ request: URLRequest) async throws -> (Data, URLResponse) {
        return try await URLSession.shared.data(for: request)
    }

}
