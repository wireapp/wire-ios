//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

class AuthenticationAPIV0: AuthenticationAPI, VersionedAPI {
    let apiService: any APIServiceProtocol

    init(apiService: any APIServiceProtocol) {
        self.apiService = apiService
    }

    var apiVersion: APIVersion {
        .v0
    }

    func login(
        email: String,
        password: String,
        verificationCode: String?,
        label: String?
    ) async throws -> ([HTTPCookie], AccessToken) {
        let path = "\(pathPrefix)/login"
        let body = LoginRequestBodyV0(
            email: email,
            password: password,
            verificationCode: verificationCode,
            label: label
        )

        let encodedJSON: Data
        do {
            encodedJSON = try JSONEncoder.defaultEncoder.encode(body)
        } catch {
            assertionFailure("failed to encode body")
            throw AuthenticationAPIError.invalidRequestBody
        }

        let request = try URLRequestBuilder(path: path)
            .withBody(encodedJSON, contentType: .json)
            .withMethod(.post)
            .build()

        let (data, response) = try await apiService.executeRequest(
            request,
            requiringAccessToken: false
        )

        guard
            let responseURL = response.url,
            let responseHeaders = response.allHeaderFields as? [String: String]
        else {
            throw AuthenticationAPIError.invalidResponse
        }

        let cookies = HTTPCookie.cookies(
            withResponseHeaderFields: responseHeaders,
            for: responseURL
        )

        let accessToken = try ResponseParser()
            .success(
                code: .ok,
                type: AccessTokenPayload.self
            )
            .failure(
                code: .forbidden,
                label: "code-authentication-required",
                error: AuthenticationAPIError.twoFactorAuthenticationRequired
            )
            .failure(
                code: .forbidden,
                label: "code-authentication-failed",
                error: AuthenticationAPIError.twoFactorAuthenticationFailed
            )
            .failure(
                code: .forbidden,
                label: "pending-activation",
                error: AuthenticationAPIError.accountPendingActivation
            )
            .failure(
                code: .forbidden,
                label: "suspended",
                error: AuthenticationAPIError.accountSuspended
            )
            .failure(
                code: .forbidden,
                label: "invalid-credentials",
                error: AuthenticationAPIError.invalidCredentials
            )
            .parse(
                code: response.statusCode,
                data: data
            )

        return (cookies, accessToken)
    }

    func getOnPremConfigURL(forDomain domain: String) async throws -> DomainInfo {
        guard !domain.isEmpty,
              let encodedDomain = domain.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
        else {
            throw AuthenticationAPIError.invalidDomain
        }

        let path = "/custom-backend/by-domain/\(encodedDomain)"

        let request = try URLRequestBuilder(path: path)
            .withMethod(.get)
            .build()

        let (data, response) = try await apiService.executeRequest(
            request,
            requiringAccessToken: false
        )

        return try ResponseParser()
            .success(code: .ok, type: DomainInfoV0.self)
            .failure(code: .notFound, label: "custom-backend-not-found", error: AuthenticationAPIError.configNotFound)
            .failure(code: .notFound, error: AuthenticationAPIError.domainNotFound)
            .parse(code: response.statusCode, data: data)
    }

    func getDomainRegistration(forEmail email: String) async throws -> DomainRegistrationConfiguration {
        throw AuthenticationAPIError.unsupportedEndpointForAPIVersion
    }
}
