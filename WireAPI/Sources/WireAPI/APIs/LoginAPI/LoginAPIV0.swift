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

class LoginAPIV0: LoginAPI, VersionedAPI {

    let networkService: NetworkService

    private lazy var encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()

    private lazy var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    var apiVersion: APIVersion { .v0 }

    init(networkService: NetworkService) {
        self.networkService = networkService
    }

    func login(
        email: String,
        password: String,
        twoFactorAuthenticationCode: String?
    ) async throws -> ([HTTPCookie], AccessToken) {
        var components = URLComponents(string: "\(pathPrefix)/login")

        // Request a persistent (not a session) cookie.
        components?.queryItems = [URLQueryItem(name: "persist", value: "true")]

        guard let url = components?.url else {
            assertionFailure("generated an invalid url")
            throw LoginAPIError.invalidURL
        }

        let requestPayload = LoginBodyPayloadV0(
            email: email,
            password: password,
            verificationCode: twoFactorAuthenticationCode,
            label: UUID().uuidString
        )

        let body: Data
        do {
            body = try encoder.encode(requestPayload)
        } catch {
            throw LoginAPIError.invalidBody(error)
        }

        let request = URLRequestBuilder(url: url)
            .withMethod(.post)
            .withBody(body, contentType: .json)
            .build()

        let (data, response) = try await networkService.executeRequest(request)

        guard
            let responseURL = response.url,
            let responseHeaders = response.allHeaderFields as? [String: String]
        else {
            throw LoginAPIError.invalidResponse
        }

        let cookies = HTTPCookie.cookies(
            withResponseHeaderFields: responseHeaders,
            for: responseURL
        )

        let accessToken = try ResponseParser(decoder: decoder)
            .success(
                code: .ok,
                type: AccessTokenPayload.self
            )
            .failure(
                code: .forbidden,
                label: "code-authentication-required",
                error: LoginAPIError.twoFactorAuthenticationRequired
            )
            .failure(
                code: .forbidden,
                label: "code-authentication-failed",
                error: LoginAPIError.twoFactorAuthenticationFailed
            )
            .failure(
                code: .forbidden,
                label: "pending-activation",
                error: LoginAPIError.accountPendingActivation
            )
            .failure(
                code: .forbidden,
                label: "suspended",
                error: LoginAPIError.accountSuspended
            )
            .failure(
                code: .forbidden,
                label: "invalid-credentials",
                error: LoginAPIError.invalidCredentials
            )
            .parse(
                code: response.statusCode,
                data: data
            )

        return (cookies, accessToken)
    }

}

public enum LoginAPIError: Error {

    case invalidURL
    case invalidBody(any Error)
    case invalidResponse
    case twoFactorAuthenticationRequired
    case twoFactorAuthenticationFailed
    case accountPendingActivation
    case accountSuspended
    case invalidCredentials
}

private struct LoginBodyPayloadV0: Encodable {

    let email: String
    let password: String
    let verificationCode: String?
    let label: String?

}
