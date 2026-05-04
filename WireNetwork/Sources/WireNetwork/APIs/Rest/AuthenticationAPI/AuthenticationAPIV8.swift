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

class AuthenticationAPIV8: AuthenticationAPIV7 {

    override var apiVersion: APIVersion {
        .v8
    }

    override func getDomainRegistration(forEmail email: String) async throws -> DomainRegistrationConfiguration {
        let path = "\(pathPrefix)/get-domain-registration"
        let body = GetDomainRegistrationParametersV8(email: email)

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
            .success(code: .ok, type: DomainRegistrationConfigurationV8.self)
            .failure(
                code: .serviceUnavailable,
                label: "enterprise-service-not-enabled",
                error: AuthenticationAPIError.serviceUnavailable
            )
            .failure(code: .badRequest, label: "invalid-domain", error: AuthenticationAPIError.invalidDomain)
            .failure(code: .badRequest, error: AuthenticationAPIError.invalidRequestBody)
            .parse(code: response.statusCode, data: data)
    }

}

// MARK: Encodables

struct GetDomainRegistrationParametersV8: Encodable {
    let email: String
}
