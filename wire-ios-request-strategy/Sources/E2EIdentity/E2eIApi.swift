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

public protocol E2eIApiInterface {

    func getWireNonce(clientId: String) async throws -> String

    func getAccessToken(clientId: String, dpopToken: String) async throws -> AccessTokenResponse

}

public class E2eIApi: E2eIApiInterface {

    // MARK: - Properties
    private let httpClient: HttpClientCustom

    // MARK: - Life cycle
    public init(httpClient: HttpClientCustom) {
        self.httpClient = httpClient
    }

    public func getWireNonce(clientId: String) async throws -> String {
        let request = ZMTransportRequest(path: "/\(Constant.pathClients)/\(clientId)/\(Constant.pathNonce)",
                                         method: .head,
                                         payload: nil,
                                         apiVersion: APIVersion.v5.rawValue)
        request.addValue(ContentType.joseJson, forAdditionalHeaderField: "Content-Type")

        let response = try await httpClient.send(request)
        guard let httpResponse = response.rawResponse,
              let replayNonce = httpResponse.value(forHTTPHeaderField: HeaderKey.replayNonce) else {
            throw NetworkError.errorDecodingResponse(response)
        }

        return replayNonce
    }

    public func getAccessToken(clientId: String, dpopToken: String) async throws -> AccessTokenResponse {
        let request = ZMTransportRequest(path: "/\(Constant.pathClients)/\(clientId)/\(Constant.pathAccessToken)",
                                         method: .post,
                                         payload: nil,
                                         apiVersion: APIVersion.v5.rawValue)
        request.addValue(dpopToken, forAdditionalHeaderField: Constant.dpopHeaderKey)
        let response = try await httpClient.send(request)

        guard let accessToken = AccessTokenResponse(response) else {
            throw NetworkError.errorDecodingResponse(response)
        }
        return accessToken
    }

}

private enum Constant {
    static let pathClients = "clients"
    static let pathNonce = "nonce"
    static let pathAccessToken = "access-token"

    static let dpopHeaderKey = "Dpop"
    static let nonceHeaderKey = "Replay-Nonce"
}
