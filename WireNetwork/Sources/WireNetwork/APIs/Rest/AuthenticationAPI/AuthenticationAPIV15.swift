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

import Foundation

final class AuthenticationAPIV15: AuthenticationAPIV14 {

    override var apiVersion: APIVersion { .v15 }

    override func getSSOCode(forEmail email: String) async throws -> UUID {
        let path = "\(pathPrefix)/sso/get-by-email"
        let body = GetSSOCodeByEmailRequestBodyV15(email: email)

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

        let (data, response) = try await networkService.executeRequest(request)

        return try ResponseParser()
            .success(code: .ok, type: SSOCodeByEmailResponseV15.self)
            .failure(code: .notFound, error: AuthenticationAPIError.ssoCodeNotFound)
            .parse(code: response.statusCode, data: data)
    }

}

// MARK: - Encodables

private struct GetSSOCodeByEmailRequestBodyV15: Encodable {
    let email: String
}
