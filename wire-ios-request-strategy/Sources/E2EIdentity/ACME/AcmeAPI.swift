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

public protocol AcmeAPI {

    func getACMEDirectory() async -> AcmeDirectoriesResponse?
    func getACMENonce(url: String) async -> String?
    func sendACMERequest(url: String, body: Data) async -> ACMEResponse?
    func sendChallengeRequest(url: String, body: Data?) async -> ChallengeResponse?

}

public class AcmeAPIV5: NSObject, AcmeAPI {

    // MARK: - Properties

    private let httpClient: HttpClient
    private let apiVersion: APIVersion = .v5

    // MARK: - Life cycle

    public init(httpClient: HttpClient) {
        self.httpClient = httpClient
    }

    public func getACMEDirectory() async -> AcmeDirectoriesResponse? {

        do {
            let path = "https://acme.\(BackendInfo.domain ?? "")/acme/defaultteams/directory"
            guard
                let url = URL(string: path) else {
                WireLogger.e2ei.warn("Invalid get acme directory url")

                return nil
            }

            var request = URLRequest(url: url)
            request.httpMethod = HTTPMethod.get.rawValue

            let (data, _) = try await executeAsync(request: request)

            return try JSONDecoder().decode(AcmeDirectoriesResponse.self, from: data)
        } catch {
            WireLogger.e2ei.info("Get acme directory request failed with error: \(error)")

            return nil
        }

    }

    public func getACMENonce(url: String) async -> String? {
        do {
            guard
                let url = URL(string: url) else {
                WireLogger.e2ei.warn("Invalid get acme nonce url")

                return nil
            }

            var request = URLRequest(url: url)
            request.httpMethod = HTTPMethod.head.rawValue

            let (_, response) = try await executeAsync(request: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                WireLogger.e2ei.warn("Invalid response")

                return nil
            }
            let replayNonce = httpResponse.value(forHTTPHeaderField: HeaderKey.replayNonce.rawValue)

            return replayNonce
        } catch {
            WireLogger.e2ei.info("Get acme nonce request failed with error: \(error)")

            return nil
        }
    }

    public func sendACMERequest(url: String, body: Data) async -> ACMEResponse? {
        guard
            let url = URL(string: url) else {
            WireLogger.e2ei.warn("Invalid send acme request url")

            return nil
        }
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.post.rawValue
        request.setValue("application/jose+json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        do {
            let (data, response) = try await executeAsync(request: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                WireLogger.e2ei.warn("Invalid response")

                return nil
            }
            guard let replayNonce = httpResponse.value(forHTTPHeaderField: HeaderKey.replayNonce.rawValue),
                  let location = httpResponse.value(forHTTPHeaderField: HeaderKey.location.rawValue) else {
                return nil
            }

            return ACMEResponse(nonce: replayNonce, location: location, response: data)
        } catch {
            WireLogger.e2ei.info("Send acme request failed with error: \(error)")

            return nil
        }
    }

//    private func handleACMERequestResponse(response: Data) -> ACMEResponse? {
//
//        return ACMEResponse(nonce: <#T##String#>, location: <#T##String#>, response: <#T##Data#>)
//    }


    public func sendChallengeRequest(url: String, body: Data?) async -> ChallengeResponse? {
        return nil
    }

    private func executeAsync(request: URLRequest) async throws -> (Data, URLResponse) {
        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
        return try await session.data(for: request)
    }

}

/// TODO: temp solution for `elna.wire.link`
extension AcmeAPIV5: URLSessionDelegate {

    public func urlSession(_ session: URLSession,
                           didReceive challenge: URLAuthenticationChallenge,
                           completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        // TODO: Temp - trust the certificate even if not valid
        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        let urlCredential = URLCredential(trust: serverTrust)

        completionHandler(.useCredential, urlCredential)
    }

}

enum HTTPMethod: String {

    case get = "GET"
    case post = "POST"
    case head = "HEAD"

}

enum HeaderKey: String {

    case replayNonce = "Replay-Nonce"
    case location = "location"

}
