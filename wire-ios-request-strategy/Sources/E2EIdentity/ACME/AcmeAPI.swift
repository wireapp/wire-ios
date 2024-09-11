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
import WireCoreCrypto

// sourcery: AutoMockable
public protocol AcmeAPIInterface {
    func getACMEDirectory() async throws -> Data
    func getACMENonce(path: String) async throws -> String
    func getTrustAnchor() async throws -> String
    func getFederationCertificates() async throws -> [String]
    func sendACMERequest(path: String, requestBody: Data) async throws -> ACMEResponse
    func sendAuthorizationRequest(path: String, requestBody: Data) async throws -> ACMEAuthorizationResponse
    func sendChallengeRequest(path: String, requestBody: Data) async throws -> ChallengeResponse
}

/// This class provides ACME(Automatic Certificate Management Environment) server methods for enrolling an E2EI
/// certificate.
public class AcmeAPI: NSObject, AcmeAPIInterface {
    // MARK: - Properties

    private let rootCertificatePath = "roots.pem"
    private let federationCertificatePath = "federation"
    private let acmeDiscoveryPath: String
    private let httpClient: HttpClientCustom
    private let decoder = JSONDecoder()

    // MARK: - Life cycle

    // TODO: [WPB-6785] refactor HttpClientE2EI
    public init(
        acmeDiscoveryPath: String,
        httpClient: HttpClientCustom = HttpClientE2EI()
    ) {
        self.acmeDiscoveryPath = acmeDiscoveryPath
        self.httpClient = httpClient
    }

    public func getACMEDirectory() async throws -> Data {
        guard let acmeDirectory = URL(string: acmeDiscoveryPath) else {
            throw NetworkError.errorEncodingRequest
        }

        var request = URLRequest(url: acmeDirectory)
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
            throw NetworkError.errorDecodingURLResponse(response)
        }

        return replayNonce
    }

    public func getTrustAnchor() async throws -> String {
        guard
            let baseURL = URL(string: acmeDiscoveryPath)?.extractBaseURL,
            let url = URL(string: rootCertificatePath, relativeTo: baseURL)
        else {
            throw NetworkError.errorEncodingRequest
        }

        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.get

        let (data, response) = try await httpClient.send(request)

        guard
            let certificateChain = String(bytes: data, encoding: .utf8)
        else {
            throw NetworkError.errorDecodingURLResponse(response)
        }

        return certificateChain
    }

    public func getFederationCertificates() async throws -> [String] {
        guard
            let baseURL = URL(string: acmeDiscoveryPath)?.extractBaseURL,
            let url = URL(string: federationCertificatePath, relativeTo: baseURL)
        else {
            throw NetworkError.errorEncodingRequest
        }

        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.get

        let (data, response) = try await httpClient.send(request)

        guard
            let certificates = try? decoder.decode(FederationCertificates.self, from: data).certificates
        else {
            throw NetworkError.errorDecodingURLResponse(response)
        }

        return certificates
    }

    public func sendACMERequest(path: String, requestBody: Data) async throws -> ACMEResponse {
        guard let url = URL(string: path) else {
            throw NetworkError.errorEncodingRequest
        }
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.post
        request.setValue(ContentType.joseAndJson, forHTTPHeaderField: Constant.contentType)
        request.httpBody = requestBody

        let (data, response) = try await httpClient.send(request)

        guard
            let httpResponse = response as? HTTPURLResponse,
            let replayNonce = httpResponse.value(forHTTPHeaderField: HeaderKey.replayNonce)
        else {
            throw NetworkError.errorDecodingURLResponse(response)
        }
        let location = httpResponse.value(forHTTPHeaderField: HeaderKey.location) ?? ""
        return ACMEResponse(nonce: replayNonce, location: location, response: data)
    }

    public func sendAuthorizationRequest(path: String, requestBody: Data) async throws -> ACMEAuthorizationResponse {
        guard let url = URL(string: path) else {
            throw NetworkError.errorEncodingRequest
        }
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.post
        request.setValue(ContentType.joseAndJson, forHTTPHeaderField: Constant.contentType)
        request.setValue(ContentType.json, forHTTPHeaderField: Constant.accept)
        request.httpBody = requestBody

        let (data, response) = try await httpClient.send(request)

        guard
            let authorizationResponse = try? decoder.decode(AuthorizationResponse.self, from: data),
            let type = authorizationResponse.challenges.first?.type,
            let httpResponse = response as? HTTPURLResponse,
            let replayNonce = httpResponse.value(forHTTPHeaderField: HeaderKey.replayNonce)
        else {
            throw NetworkError.errorDecodingURLResponse(response)
        }

        let location = httpResponse.value(forHTTPHeaderField: HeaderKey.location) ?? ""
        return ACMEAuthorizationResponse(
            nonce: replayNonce,
            location: location,
            response: data,
            challengeType: type
        )
    }

    public func sendChallengeRequest(path: String, requestBody: Data) async throws -> ChallengeResponse {
        guard let url = URL(string: path) else {
            throw NetworkError.errorEncodingRequest
        }
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.post
        request.setValue(ContentType.joseAndJson, forHTTPHeaderField: Constant.contentType)
        request.httpBody = requestBody

        let (data, response) = try await httpClient.send(request)

        guard
            let httpResponse = response as? HTTPURLResponse,
            let replayNonce = httpResponse.value(forHTTPHeaderField: HeaderKey.replayNonce),
            let challengeResponse = Challenge(data)
        else {
            throw NetworkError.errorDecodingURLResponse(response)
        }

        return ChallengeResponse(
            type: challengeResponse.type,
            url: challengeResponse.url,
            status: challengeResponse.status,
            token: challengeResponse.token,
            target: challengeResponse.target,
            nonce: replayNonce
        )
    }

    private struct Challenge: Codable, Equatable {
        var type: String
        var url: String
        var status: String
        var token: String
        var target: String
    }

    private struct AuthorizationResponse: Decodable {
        var challenges: [AuthorizationChallenge]
    }

    private struct AuthorizationChallenge: Decodable {
        var type: AuthorizationChallengeType
    }
}

enum HeaderKey {
    static let replayNonce = "Replay-Nonce"
    static let location = "location"
}

enum ContentType {
    static let json = "application/json"
    static let joseAndJson = "application/jose+json"
}

private enum HTTPMethod {
    static let get = "GET"
    static let post = "POST"
    static let head = "HEAD"
}

private enum Constant {
    static let contentType = "Content-Type"
    static let accept = "Accept"
}

public protocol HttpClientCustom {
    func send(_ request: URLRequest) async throws -> (Data, URLResponse)
}

public class HttpClientE2EI: NSObject, HttpClientCustom {
    private let urlSession: URLSession

    override public init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.urlCache = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.urlSession = URLSession(configuration: configuration)
        super.init()
    }

    public func send(_ request: URLRequest) async throws -> (Data, URLResponse) {
        try await urlSession.data(for: request)
    }
}

extension URL {
    var extractBaseURL: URL? {
        var baseURL = URLComponents(url: self, resolvingAgainstBaseURL: false)
        baseURL?.path = ""
        return baseURL?.url
    }
}
