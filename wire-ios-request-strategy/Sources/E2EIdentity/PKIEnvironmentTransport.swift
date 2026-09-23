//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

import Combine
import CoreData
import Foundation
import WireCoreCrypto
import WireLogging
import WireTransport

public final class PKIEnvironmentTransport: WireCoreCrypto.PkiEnvironmentHooks {

    let selfClientId: String
    let e2eiApi: E2eIAPI
    var oauthAuthenticate: OAuthBlock?
    let crlURLBuilder: CRLURLBuilder

    enum Error: Swift.Error {
        case idpMissingClientID
        case malFormedURL
        case oauthAuthenticateNotConfigured
    }

    public init(
        selfClientId: String,
        e2eiApi: E2eIAPI,
        crlURLbuilder: CRLURLBuilder,
        oauthAuthenticate: OAuthBlock?
    ) {
        self.selfClientId = selfClientId
        self.e2eiApi = e2eiApi
        self.crlURLBuilder = crlURLbuilder
        self.oauthAuthenticate = oauthAuthenticate
    }

    public func httpRequest(
        method: WireCoreCryptoUniffi.HttpMethod,
        url: String,
        headers: [WireCoreCryptoUniffi.HttpHeader],
        body: Data
    ) async throws -> WireCoreCryptoUniffi.HttpResponse {

        guard var url = URL(string: url) else {
            throw Error.malFormedURL
        }

        if url.path().hasSuffix("crl") {
            url = crlURLBuilder.getURL(from: url)
        }

        var request = URLRequest(url: url)
        request.httpBody = body
        request.httpMethod = method.toString()

        for header in headers {
            request.addValue(header.value, forHTTPHeaderField: header.name)
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        let headers = httpResponse.allHeaderFields.compactMap { (key: AnyHashable, value: Any) in
            if let name = key as? String, let value = value as? String {
                HttpHeader(name: name, value: value)
            } else {
                nil
            }
        }

        return HttpResponse(
            status: UInt16(httpResponse.statusCode),
            headers: headers,
            body: data
        )
    }

    private func extractClientId(from path: String) -> String? {
        guard let urlComponents = URLComponents(string: path),
              let clientId = urlComponents.queryItems?.first(where: { $0.name == "client_id" })?.value else {
            return nil
        }
        return clientId
    }

    public func authenticate(
        idp: String,
        keyAuth: String,
        acmeAud: String,
        acquisitionSnapshot: Data
    ) async throws -> String {
        guard let oauthAuthenticate else {
            throw Error.oauthAuthenticateNotConfigured
        }

        guard let clientID = extractClientId(from: idp) else {
            throw Error.idpMissingClientID
        }

        let oauthParameters = OAuthParameters(
            identityProvider: URL(string: idp)!,
            clientID: clientID,
            keyauth: keyAuth,
            acmeAudience: acmeAud,
            acquisitionSnapshot: acquisitionSnapshot
        )
        return try await oauthAuthenticate(oauthParameters).idToken
    }

    public func getBackendNonce() async throws -> String {
        try await e2eiApi.getWireNonce(clientId: selfClientId)
    }

    public func fetchBackendAccessToken(dpop: String) async throws -> String {
        try await e2eiApi.getAccessToken(clientId: selfClientId, dpopToken: dpop).token
    }

}

private extension WireCoreCryptoUniffi.HttpMethod {

    func toString() -> String {
        return switch self {
        case .get:
            "GET"
        case .post:
            "POST"
        case .put:
            "PUT"
        case .delete:
            "DELETE"
        case .patch:
            "PATCH"
        case .head:
            "HEAD"
        @unknown default:
            "GET"
        }
    }

}
