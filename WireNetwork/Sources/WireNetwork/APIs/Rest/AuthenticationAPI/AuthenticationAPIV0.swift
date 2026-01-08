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
import WireFoundation

class AuthenticationAPIV0: AuthenticationAPI, VersionedAPI {

    let networkService: any NetworkServiceProtocol

    init(networkService: any NetworkServiceProtocol) {
        self.networkService = networkService
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
            .withQueryItem(name: "persist", value: "true")
            .build()

        let (data, response) = try await networkService.executeRequest(request)

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

        let accessToken: AccessToken
        do {
            accessToken = try ResponseParser()
                .success(
                    code: .ok,
                    type: AccessTokenV0.self
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
                .failure(code: .tooManyRequests, decodableError: FailureResponseV0.self)
                .parse(
                    code: response.statusCode,
                    data: data
                )
        } catch let error as FailureResponseV0 {
            if error.code == HTTPStatusCode.tooManyRequests.rawValue, error.label == "client-error" {
                let retryAfter = responseHeaders["retry-after"].flatMap { TimeInterval($0) }
                throw AuthenticationAPIError.tooManyRequests(error.message, retyAfter: retryAfter)
            }
            throw error
        }

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

        let (data, response) = try await networkService.executeRequest(request)

        return try ResponseParser()
            .success(code: .ok, type: DomainInfoV0.self)
            .failure(code: .notFound, label: "custom-backend-not-found", error: AuthenticationAPIError.configNotFound)
            .failure(code: .notFound, error: AuthenticationAPIError.domainNotFound)
            .parse(code: response.statusCode, data: data)
    }

    func getDomainRegistration(forEmail email: String) async throws -> DomainRegistrationConfiguration {
        throw AuthenticationAPIError.unsupportedEndpointForAPIVersion
    }

    // Move to separate api
    func validateLoginToken(ssoCode: UUID) async throws {
        let path = "/sso/initiate-login/\(ssoCode.uuidString)"
        let request = try URLRequestBuilder(path: path)
            .withMethod(.head)
            .build()

        let (_, response) = try await networkService.executeRequest(request)
        if let error = AuthenticationAPIError.SSOLoginError(responseCode: response.statusCode) {
            throw error
        }

        return try ResponseParser()
            .success(code: .ok)
            .parse(code: response.statusCode, data: nil)
    }

    // Move to separate api
    func getSSOCode() async throws -> UUID? {
        let path = "/sso/settings"
        let request = try URLRequestBuilder(path: path)
            .withMethod(.get)
            .withAcceptType(.json)
            .build()

        let (data, response) = try await networkService.executeRequest(request)
        let payload = try ResponseParser()
            .success(code: .ok, type: SSOSettingsResponseV0.self)
            .parse(code: response.statusCode, data: data)

        return payload.defaultSSOCode
    }

    func requestVerificationCode(for email: String) async throws {
        let path = "\(pathPrefix)/verification-code/send"

        let body = try JSONEncoder.defaultEncoder.encode(
            RequestVerificationCodeRequestBodyV0(
                action: "login",
                email: email
            )
        )

        let request = try URLRequestBuilder(path: path)
            .withMethod(.post)
            .withBody(body, contentType: .json)
            .build()

        let (data, response) = try await networkService.executeRequest(request)
        return try ResponseParser()
            .success(code: .ok)
            .failure(code: .badRequest, label: "bad-request", error: AuthenticationAPIError.invalidEmail)
            .parse(code: response.statusCode, data: data)
    }

    func getActivationCode(forEmail email: String, basicAuth: String) async throws -> (code: String, key: String) {
        let path = "/i/users/activation-code?email=\(email)"

        let request = try URLRequestBuilder(path: path)
            .withMethod(.get)
            .addingHeader(field: "Authorization", value: "Basic \(basicAuth)")
            .build()

        let (data, response) = try await networkService.executeRequest(request)

        guard
            let responseURL = response.url,
            let responseHeaders = response.allHeaderFields as? [String: String]
        else {
            throw AuthenticationAPIError.invalidResponse
        }

        let payload = try ResponseParser()
            .success(code: .ok, type: ActivationCodeV0.self)
            .parse(code: response.statusCode, data: data)

        return (payload.code, payload.key)

    }

    func registerPersonalAccount(name: String, email: String, password: String) async throws -> [HTTPCookie] {
        let path = "\(pathPrefix)/register"

        let body = try JSONEncoder.defaultEncoder.encode(
            RegisterAccountRequestBodyV0(email: email, name: name, password: password)
        )

        let request = try URLRequestBuilder(path: path)
            .withMethod(.post)
            .withBody(body, contentType: .json)
            .build()

        let (data, response) = try await networkService.executeRequest(request)

        guard
            let responseURL = response.url,
            let responseHeaders = response.allHeaderFields as? [String: String]
        else {
            throw AuthenticationAPIError.invalidResponse
        }

        return HTTPCookie.cookies(
            withResponseHeaderFields: responseHeaders,
            for: responseURL
        )
    }

    func activateUser(email: String, key: String, code: String) async throws {
        let path = "\(pathPrefix)/activate"

        let body = try JSONEncoder.defaultEncoder.encode(
            ActivateRequestBodyV0(
                key: key,
                code: code,
                email: email,
                dryrun: false
            )
        )

        let request = try URLRequestBuilder(path: path)
            .withMethod(.post)
            .withBody(body, contentType: .json)
            .build()

        let (_, response) = try await networkService.executeRequest(request)

        try ResponseParser()
            .success(code: .ok)
            .failure(code: .badRequest, label: "bad-request", error: AuthenticationAPIError.invalidEmail)
            .parse(code: response.statusCode, data: nil)
    }

    func requestEmailVerificationCode(for email: String) async throws {
        let path = "\(pathPrefix)/activate/send"

        let body = try JSONEncoder.defaultEncoder.encode(
            RequestEmailVerificationCodeBodyV0(
                email: email,
                locale: Locale.formattedLocaleIdentifier
            )
        )

        let request = try URLRequestBuilder(path: path)
            .withMethod(.post)
            .withBody(body, contentType: .json)
            .build()

        let (data, response) = try await networkService.executeRequest(request)
        return try ResponseParser()
            .success(code: .ok)
            .failure(
                code: .badRequest,
                label: "invalid-email",
                error: AuthenticationAPIError.RegistrationError.invalidEmail
            )
            .failure(
                code: .forbidden,
                label: "blacklisted-email",
                error: AuthenticationAPIError.RegistrationError.blacklistedEmail
            )
            .failure(
                code: .conflict,
                label: "key-exists",
                error: AuthenticationAPIError.RegistrationError.keyExists
            )
            .failure(
                code: .domainBlocked,
                label: "domain-blocked-for-registration",
                error: AuthenticationAPIError.RegistrationError.domainBlocked
            )
            .parse(code: response.statusCode, data: data)
    }

    func registerAccount(
        email: String,
        emailCode: String,
        name: String,
        password: String,
        label: String
    ) async throws -> (cookie: [HTTPCookie], userId: UUID?) {
        let path = "\(pathPrefix)/register"

        let body = try JSONEncoder.defaultEncoder.encode(
            RegisterPersonalAccountBodyV0(
                email: email,
                emailCode: emailCode,
                label: label,
                locale: Locale.formattedLocaleIdentifier,
                name: name,
                password: password
            )
        )

        let request = try URLRequestBuilder(path: path)
            .withMethod(.post)
            .withBody(body, contentType: .json)
            .build()

        let (data, response) = try await networkService.executeRequest(request)
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

        let userKey = try ResponseParser()
            .success(
                code: .created,
                type: UserKeyV0.self
            )
            .failure(
                code: .badRequest,
                label: "invalid-email",
                error: AuthenticationAPIError.RegistrationError.invalidEmail
            )
            .failure(
                code: .badRequest,
                label: "invalid-invitation-code",
                error: AuthenticationAPIError.RegistrationError.invalidInvitationCode
            )
            .failure(
                code: .forbidden,
                label: "unauthorized",
                error: AuthenticationAPIError.RegistrationError.unauthorized
            )
            .failure(
                code: .forbidden,
                label: "missing-identity",
                error: AuthenticationAPIError.RegistrationError.missingIdentity
            )
            .failure(
                code: .forbidden,
                label: "blacklisted-email",
                error: AuthenticationAPIError.RegistrationError.blacklistedEmail
            )
            .failure(
                code: .forbidden,
                label: "too-many-team-members",
                error: AuthenticationAPIError.RegistrationError.tooManyTeamMembers
            )
            .failure(
                code: .forbidden,
                label: "user-creation-restricted",
                error: AuthenticationAPIError.RegistrationError.userCreationRestricted
            )
            .failure(
                code: .notFound,
                label: "invalid-code",
                error: AuthenticationAPIError.RegistrationError.invalidCode
            )
            .failure(
                code: .conflict,
                label: "key-exists",
                error: AuthenticationAPIError.RegistrationError.keyExists
            )
            .parse(
                code: response.statusCode,
                data: data
            )
        return (cookies, userKey.uuid)
    }

    func registerTeamOwner(
        email: String,
        password: String,
        name: String,
        teamName: String
    ) async throws -> (teamId: UUID?, qualifiedId: QualifiedID) {
        let path = "\(pathPrefix)/register"

        let body = try JSONEncoder.defaultEncoder.encode(
            RegisterTeamOwnerBodyV0(
                email: email,
                password: password,
                name: name,
                team: RegisterTeamOwnerBodyV0.TeamInfo(
                    name: teamName,
                    icon: "default",
                    binding: true
                )
            )
        )

        let request = try URLRequestBuilder(path: path)
            .withMethod(.post)
            .withBody(body, contentType: .json)
            .build()

        let (data, response) = try await networkService.executeRequest(request)

        let apiResponse = try ResponseParser()
            .success(code: .created, type: RegisterUserResponseV0.self)
            .parse(code: response.statusCode, data: data)

        return (apiResponse.teamID, apiResponse.qualifiedID)
    }

    func registerTeamMember(
        email: String,
        password: String,
        name: String,
        invitationCode: String
    ) async throws -> QualifiedID {
        let path = "\(pathPrefix)/register"

        let body = try JSONEncoder.defaultEncoder.encode(
            RegisterTeamMemberBodyV0(
                email: email,
                password: password,
                name: name,
                team_code: invitationCode
            )
        )

        let request = try URLRequestBuilder(path: path)
            .withMethod(.post)
            .withBody(body, contentType: .json)
            .build()

        let (data, response) = try await networkService.executeRequest(request)

        let apiResponse = try ResponseParser()
            .success(code: .created, type: RegisterUserResponseV0.self)
            .parse(code: response.statusCode, data: data)

        return apiResponse.qualifiedID
    }

    func getInvitationCode(teamID: UUID, invitationID: UUID) async throws -> String {
        let path = "/i/teams/invitation-code?team=\(teamID)&invitation_id=\(invitationID)"
        let auth = ProcessInfo.processInfo.environment["BASIC_AUTH"]!

        let request = try URLRequestBuilder(path: path)
            .withMethod(.get)
            .addingHeader(field: "Authorization", value: "Basic \(auth)")
            .build()

        let (data, response) = try await networkService.executeRequest(request)
        let payload = try ResponseParser()
            .success(code: .ok, type: InvitationCodeResponseV0.self)
            .parse(code: response.statusCode, data: data)

        return payload.code
    }
}

private struct RegisterAccountRequestBodyV0: Encodable {
    var email: String
    var name: String
    var password: String
}

private struct ActivateRequestBodyV0: Encodable {
    var key: String
    var code: String
    var email: String
    var dryrun: Bool
}

private struct RegisterTeamOwnerBodyV0: Encodable {
    var email: String
    var password: String
    var name: String
    var team: TeamInfo

    struct TeamInfo: Encodable {
        var name: String
        var icon: String
        var binding: Bool
    }
}

private struct RegisterTeamMemberBodyV0: Encodable {
    var email: String
    var password: String
    var name: String
    var team_code: String
}

struct RegisterUserResponseV0: Decodable, ToAPIModelConvertible {

    let accentID: Int
    let assets: [UserAssetV0]?
    let email: String?
    let id: String
    let locale: String
    let managedBy: ManagedByV0?
    let name: String
    // removed picture from parsing - WPB-20534
    let qualifiedID: QualifiedIDV0
    let status: String?
    let teamID: UUID?

    enum CodingKeys: String, CodingKey {
        case accentID = "accent_id"
        case assets, email
        case id
        case locale
        case managedBy = "managed_by"
        case name
        case qualifiedID = "qualified_id"
        case status
        case teamID = "team"
    }

    func toAPIModel() -> RegisterUserResponse {
        RegisterUserResponse(
            id: id,
            qualifiedID: qualifiedID.toAPIModel(),
            name: name,
            teamID: teamID,
            accentID: accentID,
            managedBy: managedBy?.toAPIModel(),
            assets: assets?.map { $0.toAPIModel() },
            email: email,
            status: status,
            supportedProtocols: [.proteus]
        )
    }
}
