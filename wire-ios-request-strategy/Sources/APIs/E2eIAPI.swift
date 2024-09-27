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

// MARK: - E2eIAPI

// sourcery: AutoMockable
public protocol E2eIAPI {
    func getWireNonce(clientId: String) async throws -> String

    func getAccessToken(clientId: String, dpopToken: String) async throws -> AccessTokenResponse
}

// MARK: - E2eIAPIV5

class E2eIAPIV5: E2eIAPI {
    // MARK: Lifecycle

    init(httpClient: HttpClient) {
        self.httpClient = httpClient
    }

    // MARK: Open

    open var apiVersion: APIVersion {
        .v5
    }

    // MARK: Internal

    let httpClient: HttpClient

    func getWireNonce(clientId: String) async throws -> String {
        let request = ZMTransportRequest(
            path: "/\(Constant.pathClients)/\(clientId)/\(Constant.pathNonce)",
            method: .head,
            payload: nil,
            apiVersion: apiVersion.rawValue
        )
        request.addValue(ContentType.joseAndJson, forAdditionalHeaderField: Constant.contentType)

        let response = await httpClient.send(request)
        guard let httpResponse = response.rawResponse,
              let replayNonce = httpResponse.value(forHTTPHeaderField: HeaderKey.replayNonce) else {
            throw NetworkError.errorDecodingResponse(response)
        }

        return replayNonce
    }

    func getAccessToken(clientId: String, dpopToken: String) async throws -> AccessTokenResponse {
        let request = ZMTransportRequest(
            path: "/\(Constant.pathClients)/\(clientId)/\(Constant.pathAccessToken)",
            method: .post,
            payload: nil,
            apiVersion: apiVersion.rawValue
        )
        request.addValue(dpopToken, forAdditionalHeaderField: Constant.dpopHeaderKey)
        let response = await httpClient.send(request)

        return try mapResponse(response)
    }
}

// MARK: - E2eIAPIV6

class E2eIAPIV6: E2eIAPIV5 {
    override var apiVersion: APIVersion {
        .v6
    }
}

// MARK: - Constant

private enum Constant {
    static let pathClients = "clients"
    static let pathNonce = "nonce"
    static let pathAccessToken = "access-token"

    static let contentType = "Content-Type"
    static let dpopHeaderKey = "Dpop"
    static let nonceHeaderKey = "Replay-Nonce"
}
