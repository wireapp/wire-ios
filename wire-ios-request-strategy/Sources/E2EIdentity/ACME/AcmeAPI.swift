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
    func sendACMERequest(url: String, body: ZMTransportData) async -> ACMEResponse?
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

            let responseData = try await executeAsync(request: request)

            return try JSONDecoder().decode(AcmeDirectoriesResponse.self, from: responseData)
        } catch {
            WireLogger.e2ei.info("Get acme directory request failed with error: \(error)")

            return nil
        }

    }

    public func getACMENonce(url: String) async -> String? {

//        let request = ZMTransportRequest(path: url,
//                                         method: .methodHEAD,
//                                         payload: nil,
//                                         apiVersion: apiVersion.rawValue)
//
//        let response = await httpClient.send(request)
//        guard response.result == .success else {
//            return nil
//        }
//
//        return response.rawResponse?.allHeaderFields[HeaderKey.replayNonce.rawValue] as? String
        return nil
    }

    public func sendACMERequest(url: String, body: ZMTransportData) async -> ACMEResponse? {
        return nil

    }

    public func sendChallengeRequest(url: String, body: Data?) async -> ChallengeResponse? {
        return nil
    }

    private func executeAsync(request: URLRequest) async throws -> Data {
        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
        let (data, _) = try await session.data(for: request)

        return data
    }

}

extension AcmeAPIV5: URLSessionDelegate {

    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
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
