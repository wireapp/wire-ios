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
import WireNetwork

@MainActor
final class SSOHelper {
    private let userHelper: UserHelper
    private let httpClient: HttpClient
    private let keycloakBaseURL: URL?

    private var keycloakSAMLClientId: String?
    private var keycloakUserIds: [String] = []
    private var scimAuthToken: String?
    private(set) var identityProviderId: String?

    init(
        userHelper: UserHelper = UserHelper.default,
        httpClient: HttpClient = HttpClient(),
        keycloakBaseURL: URL? = nil
    ) {
        self.userHelper = userHelper
        self.httpClient = httpClient
        self.keycloakBaseURL = keycloakBaseURL
    }

    @discardableResult
    func createSSOUserAsSelf(user: UserInfo) async throws -> UserInfo {
        let owner = try await createSSOUserForKeycloak(user: user)
        return try await addUserToKeycloak(user: owner)
    }

    @discardableResult
    func createSSOUser(owner: UserInfo, ssoUser: UserInfo) async throws -> UserInfo {
        _ = try await createSSOUserForKeycloak(user: owner)
        return try await addUserToKeycloak(user: ssoUser)
    }

    @discardableResult
    func createSCIMManagedSSOUser(owner: UserInfo, ssoUser: UserInfo) async throws -> UserInfo {
        _ = try await createSSOUserForKeycloak(user: owner)

        prepareSSOUser(ssoUser)

        _ = try await createKeycloakUser(
            username: ssoUser.email,
            firstName: ssoUser.name,
            lastName: ssoUser.name,
            email: ssoUser.email,
            password: ssoUser.password
        )

        ssoUser.id = try await createSCIMUser(owner: owner, user: ssoUser)
        userHelper.addUser(ssoUser)
        return ssoUser
    }

    @discardableResult
    func createSSOUserForKeycloak(user: UserInfo) async throws -> UserInfo {
        let teamID = try teamID(for: user)
        let metadata = try await getKeycloakMetadata()
        identityProviderId = try await createIdentityProviderV2(user: user, metadata: metadata)
        try await createKeycloakSAMLClient(teamID: teamID)
        return user
    }

    @discardableResult
    func addUserToKeycloak(user: UserInfo) async throws -> UserInfo {
        prepareSSOUser(user)

        _ = try await createKeycloakUser(
            username: user.email,
            firstName: user.name,
            lastName: user.name,
            email: user.email,
            password: user.password
        )

        userHelper.addUser(user)
        return user
    }

    func enableSSOFeature(teamID: UUID) async throws {
        let backOffice = BackOffice(backendURL: userHelper.backendURL)
        try await backOffice.enableSSOFeature(
            teamId: teamID.uuidString,
            basicAuth: userHelper.basicAuth()
        )
    }

    func getSSOCode() throws -> String {
        guard let identityProviderId else {
            throw RuntimeError("getSSOCode: identityProviderId is nil")
        }
        return "wire-\(identityProviderId)"
    }

    func cleanUpSSOResources() async {
        if let keycloakSAMLClientId {
            await cleanUpKeycloakSAMLClient(keycloakSAMLClientId)
            self.keycloakSAMLClientId = nil
        }

        for userId in keycloakUserIds {
            await cleanUpKeycloakUser(userId)
        }
        keycloakUserIds.removeAll()
    }

    private func prepareSSOUser(_ user: UserInfo) {
        user.password = "SSO\(user.password)"
        user.name = user.email
        user.isSSOUser = true
    }

    private func teamID(for user: UserInfo) throws -> UUID {
        guard let teamID = user.teamID else {
            throw RuntimeError("teamID is nil")
        }
        return teamID
    }

    private func getKeycloakMetadata() async throws -> String {
        let url = try keycloakURL(path: ["realms", Self.realm, "protocol", "saml", "descriptor"])
        let (data, response) = try await httpClient.send(
            url: url,
            method: .get,
            body: Data(),
            headers: [
                HttpClient.HeaderKey.accept: Self.applicationXML,
                HttpClient.HeaderKey.contentType: Self.applicationXML
            ]
        )

        guard response.statusCode == 200 else {
            throw RuntimeError(
                "getKeycloakMetadata failed: HTTP \(response.statusCode) \(String(data: data, encoding: .utf8) ?? "")"
            )
        }

        guard let xml = String(data: data, encoding: .utf8), !xml.isEmpty else {
            throw RuntimeError("getKeycloakMetadata empty response")
        }

        return xml
    }

    private func createIdentityProviderV2(user: UserInfo, metadata: String) async throws -> String {
        let accessToken = try await userHelper.fetchAccessToken(email: user.email, password: user.password)
        let url = try identityProvidersV2URL()

        let (data, response) = try await httpClient.send(
            url: url,
            method: .post,
            body: Data(metadata.utf8),
            headers: [
                HttpClient.HeaderKey.accept: HttpClient.ContentType.json,
                HttpClient.HeaderKey.contentType: Self.applicationXML,
                HttpClient.HeaderKey.authorization: "Bearer \(accessToken.token)"
            ]
        )

        guard response.statusCode == 200 || response.statusCode == 201 else {
            throw RuntimeError(
                "createIdentityProviderV2 failed: HTTP \(response.statusCode) \(String(data: data, encoding: .utf8) ?? "")"
            )
        }

        let object = try JSONSerialization.jsonObject(with: data, options: [])
        guard let json = object as? [String: Any],
              let id = json["id"] as? String else {
            throw RuntimeError("createIdentityProviderV2: failed to parse identity provider id")
        }

        return id
    }

    private func createKeycloakSAMLClient(teamID: UUID) async throws {
        let finalizeURL = getFinalizeURL(teamID: teamID)
        let requestBody: [String: Any] = [
            "clientId": finalizeURL,
            "enabled": true,
            "adminUrl": "",
            "baseUrl": "",
            "rootUrl": "",
            "name": "",
            "description": "",
            "redirectUris": [finalizeURL],
            "webOrigins": [sanitizedBackendURL()],
            "protocol": "saml",
            "attributes": [
                "display.on.consent.screen": "false",
                "saml.encrypt": "false",
                "saml_assertion_consumer_url_post": finalizeURL,
                "saml.client.signature": "false",
                "saml.artifact.binding": "false",
                "saml.assertion.signature": "true",
                "saml.onetimeuse.condition": "false",
                "saml.server.signature.keyinfo.ext": "false",
                "saml.server.signature.keyinfo.xmlSigKeyInfoKeyNameTransformer": "NONE"
            ]
        ]

        let (data, response) = try await sendKeycloakRequest(
            path: ["admin", "realms", Self.realm, "clients"],
            method: .post,
            body: try JSONSerialization.data(withJSONObject: requestBody, options: [])
        )

        guard response.statusCode == 201 else {
            throw RuntimeError(
                "createKeycloakSAMLClient failed: HTTP \(response.statusCode) \(String(data: data, encoding: .utf8) ?? "")"
            )
        }

        guard let location = response.value(forHTTPHeaderField: "Location"),
              let id = location.split(separator: "/").last else {
            throw RuntimeError("createKeycloakSAMLClient: missing Location header")
        }

        keycloakSAMLClientId = String(id)
    }

    @discardableResult
    private func createKeycloakUser(
        username: String,
        firstName: String,
        lastName: String,
        email: String,
        password: String
    ) async throws -> String {
        let requestBody: [String: Any] = [
            "username": username,
            "firstName": firstName,
            "lastName": lastName,
            "email": email,
            "emailVerified": true,
            "enabled": true,
            "credentials": [
                [
                    "type": "password",
                    "value": password,
                    "temporary": false
                ]
            ]
        ]

        let (data, response) = try await sendKeycloakRequest(
            path: ["admin", "realms", Self.realm, "users"],
            method: .post,
            body: try JSONSerialization.data(withJSONObject: requestBody, options: [])
        )

        guard response.statusCode == 201 else {
            throw RuntimeError(
                "createKeycloakUser failed: HTTP \(response.statusCode) \(String(data: data, encoding: .utf8) ?? "")"
            )
        }

        guard let location = response.value(forHTTPHeaderField: "Location"),
              let id = location.split(separator: "/").last else {
            throw RuntimeError("createKeycloakUser: missing Location header")
        }

        let userId = String(id)
        keycloakUserIds.append(userId)
        return userId
    }

    private func cleanUpKeycloakSAMLClient(_ clientId: String) async {
        do {
            _ = try await sendKeycloakRequest(
                path: ["admin", "realms", Self.realm, "clients", clientId],
                method: .delete,
                body: Data(),
                expectedStatusCodes: [204]
            )
        } catch {
            print("Failed to clean up Keycloak SAML client \(clientId): \(error)")
        }
    }

    private func cleanUpKeycloakUser(_ userId: String) async {
        do {
            _ = try await sendKeycloakRequest(
                path: ["admin", "realms", Self.realm, "users", userId],
                method: .delete,
                body: Data(),
                expectedStatusCodes: [204]
            )
        } catch {
            print("Failed to clean up Keycloak user \(userId): \(error)")
        }
    }

    @discardableResult
    private func createSCIMUser(owner: UserInfo, user: UserInfo) async throws -> String {
        let profile: [String: Any] = [
            "externalId": user.email,
            "userName": user.username,
            "displayName": user.name
        ]

        let (data, response) = try await sendSCIMRequest(
            path: ["Users"],
            method: .post,
            body: try JSONSerialization.data(withJSONObject: profile, options: [])
        ) {
            try await scimAuthorizationHeader(owner: owner)
        }

        try verifySCIMResponse(data: data, response: response, operation: "createSCIMUser")

        let object = try JSONSerialization.jsonObject(with: data, options: [])
        guard let json = object as? [String: Any],
              let id = json["id"] as? String else {
            throw RuntimeError("createSCIMUser: failed to parse user id")
        }

        return id
    }

    private func sendSCIMRequest(
        path: [String],
        method: HttpClient.Method,
        body: Data,
        authorizationHeader: () async throws -> String
    ) async throws -> (Data, HTTPURLResponse) {
        try await httpClient.send(
            url: scimURL(path: path),
            method: method,
            body: body,
            headers: [
                HttpClient.HeaderKey.accept: HttpClient.ContentType.json,
                HttpClient.HeaderKey.contentType: "application/scim+json",
                HttpClient.HeaderKey.authorization: try await authorizationHeader()
            ]
        )
    }

    private func createSCIMAuthToken(owner: UserInfo) async throws -> String {
        let accessToken = try await userHelper.fetchAccessToken(email: owner.email, password: owner.password)
        let body = try JSONSerialization.data(
            withJSONObject: [
                "description": "SCIM",
                "password": owner.password
            ],
            options: []
        )

        let (data, response) = try await httpClient.send(
            url: userHelper.backendURL
                .appendingPathComponent("scim")
                .appendingPathComponent("auth-tokens"),
            method: .post,
            body: body,
            headers: [
                HttpClient.HeaderKey.accept: HttpClient.ContentType.json,
                HttpClient.HeaderKey.contentType: HttpClient.ContentType.jsonUtf8,
                HttpClient.HeaderKey.authorization: "Bearer \(accessToken.token)"
            ]
        )

        guard response.statusCode == 200 else {
            throw RuntimeError(
                "createSCIMAuthToken failed: HTTP \(response.statusCode) \(String(data: data, encoding: .utf8) ?? "")"
            )
        }

        let object = try JSONSerialization.jsonObject(with: data, options: [])
        guard let json = object as? [String: Any],
              let token = json["token"] as? String else {
            throw RuntimeError("createSCIMAuthToken: failed to parse token")
        }

        scimAuthToken = token
        return token
    }

    private func scimAuthorizationHeader(owner: UserInfo) async throws -> String {
        if let scimAuthToken {
            return "Bearer \(scimAuthToken)"
        }

        return "Bearer \(try await createSCIMAuthToken(owner: owner))"
    }

    private func verifySCIMResponse(data: Data, response: HTTPURLResponse, operation: String) throws {
        guard response.statusCode < 400 else {
            throw RuntimeError(
                "\(operation) failed: HTTP \(response.statusCode) \(String(data: data, encoding: .utf8) ?? "")"
            )
        }
    }

    private func sendKeycloakRequest(
        path: [String],
        method: HttpClient.Method,
        body: Data,
        expectedStatusCodes: Set<Int> = [200, 201, 204]
    ) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await httpClient.send(
            url: try keycloakURL(path: path),
            method: method,
            body: body,
            headers: try await keycloakJSONHeaders()
        )

        guard expectedStatusCodes.contains(response.statusCode) else {
            throw RuntimeError(
                "Keycloak request failed: HTTP \(response.statusCode) \(String(data: data, encoding: .utf8) ?? "")"
            )
        }

        return (data, response)
    }

    private func keycloakJSONHeaders() async throws -> [String: String] {
        [
            HttpClient.HeaderKey.accept: HttpClient.ContentType.json,
            HttpClient.HeaderKey.contentType: HttpClient.ContentType.jsonUtf8,
            HttpClient.HeaderKey.authorization: "Bearer \(try await keycloakAccessToken())"
        ]
    }

    private func keycloakAccessToken() async throws -> String {
        let body = formURLEncodedBody([
            "client_id": "admin-cli",
            "username": Self.adminUser,
            "password": try keycloakAdminPassword(),
            "grant_type": "password"
        ])

        let (data, response) = try await httpClient.send(
            url: try keycloakURL(path: ["realms", Self.realm, "protocol", "openid-connect", "token"]),
            method: .post,
            body: Data(body.utf8),
            headers: [
                HttpClient.HeaderKey.accept: HttpClient.ContentType.json,
                HttpClient.HeaderKey.contentType: Self.formURLEncoded
            ]
        )

        guard response.statusCode == 200 else {
            throw RuntimeError(
                "keycloakAccessToken failed: HTTP \(response.statusCode) \(String(data: data, encoding: .utf8) ?? "")"
            )
        }

        let object = try JSONSerialization.jsonObject(with: data, options: [])
        guard let json = object as? [String: Any],
              let token = json["access_token"] as? String else {
            throw RuntimeError("keycloakAccessToken: failed to parse access_token")
        }

        return token
    }

    private func keycloakURL(path: [String]) throws -> URL {
        let base = try keycloakBaseURL ?? EnvironmentVariables().keycloakURL
        return path.reduce(base) {
            $0.appendingPathComponent($1)
        }
    }

    private func scimURL(path: [String]) -> URL {
        path.reduce(
            userHelper.backendURL
                .appendingPathComponent("scim")
                .appendingPathComponent("v2")
        ) { partialURL, component in
            partialURL.appendingPathComponent(component)
        }
    }

    private func identityProvidersV2URL() throws -> URL {
        let base = userHelper.backendURL
            .appendingPathComponent(String(describing: userHelper.apiVersion))
            .appendingPathComponent("identity-providers")

        guard var components = URLComponents(url: base, resolvingAgainstBaseURL: false) else {
            throw RuntimeError("Invalid identity provider URL")
        }
        components.queryItems = [URLQueryItem(name: "api_version", value: "v2")]

        guard let url = components.url else {
            throw RuntimeError("Invalid identity provider v2 URL")
        }
        return url
    }

    private func getFinalizeURL(teamID: UUID) -> String {
        "\(sanitizedBackendURL())/sso/finalize-login/\(teamID.uuidString.lowercased())"
    }

    private func sanitizedBackendURL() -> String {
        let backend = userHelper.backendURL.absoluteString
        return backend.hasSuffix("/") ? String(backend.dropLast()) : backend
    }

    private func keycloakAdminPassword() throws -> String {
        try EnvironmentVariables().keycloakAdminPassword
    }

    private func formURLEncodedBody(_ values: [String: String]) -> String {
        values
            .map { key, value in
                "\(formURLEncode(key))=\(formURLEncode(value))"
            }
            .joined(separator: "&")
    }

    private func formURLEncode(_ value: String) -> String {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._*")
        return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
    }

    private static let realm = "master"
    private static let adminUser = "admin"
    private static let applicationXML = "application/xml"
    private static let formURLEncoded = "application/x-www-form-urlencoded"
}
