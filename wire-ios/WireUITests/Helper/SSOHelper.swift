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

class SSOHelper {
    private let userHelper: UserHelper
    private let httpClient = HttpClient()
    private let oktaBaseURL: URL = .init(string: "https://dev-500508.oktapreview.com")!

    private var oktaApplicationId: String?
    private var oktaUserIds: [String] = []
    private(set) var identityProviderId: String?

    init(userHelper: UserHelper = UserHelper()) {
        self.userHelper = userHelper
    }

    @discardableResult
    func createSSOUserAsSelf(user: UserInfo) async throws -> UserInfo {
        let owner = try await createSSOUserForOkta(user: user)
        return try await addUserToOkta(owner: owner)
    }

    @discardableResult
    func createSSOUserForOkta(user: UserInfo) async throws -> UserInfo {
        let finalizeURL = getFinalizeURLDependingOnBackend()
        let appLabel = "SSO-\(user.teamName)"

        _ = try await createOktaApplication(label: appLabel, finalizeURL: finalizeURL)
        let metadata = try await getOktaApplicationMetadata()
        identityProviderId = try await createIdentityProvider(user: user, metadata: metadata)

        return user
    }

    @discardableResult
    func addUserToOkta(owner: UserInfo) async throws -> UserInfo {
        owner.isSSOUser = true

        _ = try await createOktaUser(name: owner.name, email: owner.email, password: owner.password)

        userHelper.addUser(owner)
        return owner
    }

    /// Enables the SSO feature through BackOffice.
    func enableSSOFeature(teamID: UUID) async throws {
        let backOffice = BackOffice(backendURL: userHelper.backendURL)
        try await backOffice.enableSSOFeature(teamId: teamID.uuidString, basicAuth: userHelper.basicAuth())
    }

    @discardableResult
    func createOktaApplication(label: String, finalizeURL: String) async throws -> String {
        let url = oktaBaseURL
            .appendingPathComponent("api")
            .appendingPathComponent("v1")
            .appendingPathComponent("apps")

        var body: [String: Any] = [
            "label": "Custom Saml 2.0 App2",
            "visibility": [
                "autoSubmitToolbar": false
            ],
            "signOnMode": "SAML_2_0",
            "credentials": [
                "userNameTemplate": [
                    "template": "${fn:substringBefore(source.login, \"@\")}",
                    "type": "BUILT_IN"
                ]
            ],
            "settings": [
                "signOn": [
                    "ssoAcsUrl": "will be replaced",
                    "idpIssuer": "https://www.okta.com/${org.externalKey}",
                    "audience": "will be replaced",
                    "recipient": "will be replaced",
                    "destination": "will be replaced",
                    "subjectNameIdTemplate": "${user.email}",
                    "subjectNameIdFormat": "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress",
                    "responseSigned": true,
                    "assertionSigned": true,
                    "signatureAlgorithm": "RSA_SHA256",
                    "digestAlgorithm": "SHA256",
                    "honorForceAuthn": true,
                    "authnContextClassRef": "urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport",
                    "requestCompressed": false
                ]
            ]
        ]

        body["label"] = label

        if var settings = body["settings"] as? [String: Any],
           var signOn = settings["signOn"] as? [String: Any] {

            signOn["ssoAcsUrl"] = finalizeURL
            signOn["audience"] = finalizeURL
            signOn["recipient"] = finalizeURL
            signOn["destination"] = finalizeURL

            settings["signOn"] = signOn
            body["settings"] = settings
        }

        let jsonBody = try JSONSerialization.data(withJSONObject: body, options: [])
        let (data, response) = try await httpClient.send(
            url: url,
            method: .post,
            body: jsonBody,
            headers: [
                HttpClient.HeaderKey.accept: HttpClient.ContentType.json,
                HttpClient.HeaderKey.contentType: "application/json;charset=UTF-8",
                HttpClient.HeaderKey.authorization: try oktaAuthorizationHeader()
            ]
        )

        guard response.statusCode == 200 else {
            throw RuntimeError(
                "createOktaApplication failed: HTTP \(response.statusCode) \(String(data: data, encoding: .utf8) ?? "")"
            )
        }

        let object = try JSONSerialization.jsonObject(with: data, options: [])
        guard let json = object as? [String: Any],
              let applicationId = json["id"] as? String else {
            throw RuntimeError("createOktaApplication: failed to parse application id")
        }

        oktaApplicationId = applicationId

        let everyoneGroupId = try await fetchGroupId(named: "Everyone")
        try await assignApplicationToGroup(applicationId: applicationId, groupId: everyoneGroupId)

        return applicationId
    }

    func fetchGroupId(named groupName: String) async throws -> String {
        let url = oktaBaseURL
            .appendingPathComponent("api")
            .appendingPathComponent("v1")
            .appendingPathComponent("groups")

        let (data, response) = try await httpClient.send(
            url: url,
            method: .get,
            body: Data(),
            headers: [
                HttpClient.HeaderKey.accept: HttpClient.ContentType.json,
                HttpClient.HeaderKey.contentType: HttpClient.ContentType.jsonUtf8,
                HttpClient.HeaderKey.authorization: try oktaAuthorizationHeader()
            ]
        )

        guard response.statusCode == 200 else {
            throw RuntimeError(
                "fetchGroupId failed: HTTP \(response.statusCode) \(String(data: data, encoding: .utf8) ?? "")"
            )
        }

        let object = try JSONSerialization.jsonObject(with: data, options: [])
        guard let groups = object as? [[String: Any]] else {
            throw RuntimeError("fetchGroupId: failed to parse groups response")
        }

        for group in groups {
            if let profile = group["profile"] as? [String: Any],
               let name = profile["name"] as? String,
               name == groupName,
               let id = group["id"] as? String {
                return id
            }
        }

        throw RuntimeError("fetchGroupId: group not found: \(groupName)")
    }

    func assignApplicationToGroup(applicationId: String, groupId: String) async throws {
        let url = oktaBaseURL
            .appendingPathComponent("api")
            .appendingPathComponent("v1")
            .appendingPathComponent("apps")
            .appendingPathComponent(applicationId)
            .appendingPathComponent("groups")
            .appendingPathComponent(groupId)

        let emptyBody = try JSONSerialization.data(withJSONObject: [:], options: [])
        let (data, response) = try await httpClient.send(
            url: url,
            method: .put,
            body: emptyBody,
            headers: [
                HttpClient.HeaderKey.accept: HttpClient.ContentType.json,
                HttpClient.HeaderKey.contentType: HttpClient.ContentType.jsonUtf8,
                HttpClient.HeaderKey.authorization: try oktaAuthorizationHeader()
            ]
        )

        guard response.statusCode == 200 else {
            throw RuntimeError(
                "assignApplicationToGroup failed: HTTP \(response.statusCode) \(String(data: data, encoding: .utf8) ?? "")"
            )
        }
    }

    func getOktaApplicationMetadata() async throws -> String {
        guard let oktaApplicationId else {
            throw RuntimeError("getOktaApplicationMetadata: oktaApplicationId is nil")
        }

        let url = oktaBaseURL
            .appendingPathComponent("api")
            .appendingPathComponent("v1")
            .appendingPathComponent("apps")
            .appendingPathComponent(oktaApplicationId)
            .appendingPathComponent("sso")
            .appendingPathComponent("saml")
            .appendingPathComponent("metadata")

        let (data, response) = try await httpClient.send(
            url: url,
            method: .get,
            body: Data(),
            headers: [
                HttpClient.HeaderKey.accept: "application/xml",
                HttpClient.HeaderKey.contentType: HttpClient.ContentType.jsonUtf8,
                HttpClient.HeaderKey.authorization: try oktaAuthorizationHeader()
            ]
        )

        guard response.statusCode == 200 else {
            throw RuntimeError(
                "getOktaApplicationMetadata failed: HTTP \(response.statusCode) \(String(data: data, encoding: .utf8) ?? "")"
            )
        }

        guard let xml = String(data: data, encoding: .utf8), !xml.isEmpty else {
            throw RuntimeError("getOktaApplicationMetadata: empty response")
        }

        return xml
    }

    func createIdentityProvider(user: UserInfo, metadata: String) async throws -> String {
        let accessToken = try await userHelper.fetchAccessToken(email: user.email, password: user.password)
        let url = userHelper.backendURL
            .appendingPathComponent(String(describing: userHelper.apiVersion))
            .appendingPathComponent("identity-providers")

        let metadataBody = Data(metadata.utf8)
        let (data, response) = try await httpClient.send(
            url: url,
            method: .post,
            body: metadataBody,
            headers: [
                HttpClient.HeaderKey.accept: HttpClient.ContentType.json,
                HttpClient.HeaderKey.contentType: "application/xml",
                HttpClient.HeaderKey.authorization: "Bearer \(accessToken.token)"
            ]
        )

        guard response.statusCode == 200 || response.statusCode == 201 else {
            throw RuntimeError(
                "createIdentityProvider failed: HTTP \(response.statusCode) \(String(data: data, encoding: .utf8) ?? "")"
            )
        }

        let object = try JSONSerialization.jsonObject(with: data, options: [])
        guard let json = object as? [String: Any],
              let id = json["id"] as? String else {
            throw RuntimeError("createIdentityProvider: failed to parse identity provider id")
        }

        return id
    }

    @discardableResult
    func createOktaUser(name: String, email: String, password: String) async throws -> String {
        var components = URLComponents(
            url: oktaBaseURL
                .appendingPathComponent("api")
                .appendingPathComponent("v1")
                .appendingPathComponent("users"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [URLQueryItem(name: "activate", value: "true")]

        guard let url = components?.url else {
            throw RuntimeError("createOktaUser: failed to build URL")
        }

        let body: [String: Any] = [
            "profile": [
                "firstName": name,
                "lastName": name,
                "email": email,
                "login": email
            ],
            "credentials": [
                "password": [
                    "value": password
                ],
                "recovery_question": [
                    "question": "What is the answer to life, the universe and everything?",
                    "answer": "fortytwo"
                ]
            ]
        ]

        let jsonBody = try JSONSerialization.data(withJSONObject: body, options: [])
        let (data, response) = try await httpClient.send(
            url: url,
            method: .post,
            body: jsonBody,
            headers: [
                HttpClient.HeaderKey.accept: HttpClient.ContentType.json,
                HttpClient.HeaderKey.contentType: HttpClient.ContentType.jsonUtf8,
                HttpClient.HeaderKey.authorization: try oktaAuthorizationHeader()
            ]
        )

        guard response.statusCode == 200 else {
            throw RuntimeError(
                "createOktaUser failed: HTTP \(response.statusCode) \(String(data: data, encoding: .utf8) ?? "")"
            )
        }

        let object = try JSONSerialization.jsonObject(with: data, options: [])
        guard let json = object as? [String: Any],
              let id = json["id"] as? String else {
            throw RuntimeError("createOktaUser: failed to parse Okta user id")
        }

        oktaUserIds.append(id)
        return id
    }

    func getSSOCode() throws -> String {
        guard let identityProviderId else {
            throw RuntimeError("getSSOCode: identityProviderId is nil")
        }
        return "wire-\(identityProviderId)"
    }

    private func oktaAuthorizationHeader() throws -> String {
        let apiKey = ProcessInfo.processInfo.environment["OKTA_API_KEY_IOS"]?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let apiKey, !apiKey.isEmpty else {
            throw RuntimeError("Missing OKTA_API_KEY_IOS")
        }

        return "SSWS \(apiKey)"
    }

    private func getFinalizeURLDependingOnBackend() -> String {
        let backend = userHelper.backendURL.absoluteString
        let sanitizedBackend = backend.hasSuffix("/") ? String(backend.dropLast()) : backend
        return sanitizedBackend + "/sso/finalize-login"
    }
    
    func cleanUpOktaResources() async {
            if let oktaApplicationId {
                do {
                    let deactivateURL = oktaBaseURL
                        .appendingPathComponent("api")
                        .appendingPathComponent("v1")
                        .appendingPathComponent("apps")
                        .appendingPathComponent(oktaApplicationId)
                        .appendingPathComponent("lifecycle")
                        .appendingPathComponent("deactivate")

    let (_, deactivateResponse) = try await httpClient.send(
                        url: deactivateURL,
                        method: .post,
                        body: Data(),
                        headers: [
                            HttpClient.HeaderKey.accept: HttpClient.ContentType.json,
                            HttpClient.HeaderKey.contentType: HttpClient.ContentType.jsonUtf8,
                            HttpClient.HeaderKey.authorization: try oktaAuthorizationHeader()
                        ]
                    )

    if deactivateResponse.statusCode == 200 {
                        let deleteURL = oktaBaseURL
                            .appendingPathComponent("api")
                            .appendingPathComponent("v1")
                            .appendingPathComponent("apps")
                            .appendingPathComponent(oktaApplicationId)

    let (_, deleteResponse) = try await httpClient.send(
                            url: deleteURL,
                            method: .delete,
                            body: Data(),
                            headers: [
                                HttpClient.HeaderKey.accept: HttpClient.ContentType.json,
                                HttpClient.HeaderKey.contentType: HttpClient.ContentType.jsonUtf8,
                                HttpClient.HeaderKey.authorization: try oktaAuthorizationHeader()
                            ]
                        )

    if deleteResponse.statusCode != 204 {
                            print("❌ Failed to delete Okta application (oktaApplicationId)")
                        }
                    } else {
                        print("❌ Failed to deactivate Okta application (oktaApplicationId)")
                    }
                } catch {
                    print("❌ Failed to clean up Okta application: (error)")
                }
            }

    for userId in oktaUserIds {
                do {
                    let deactivateURL = oktaBaseURL
                        .appendingPathComponent("api")
                        .appendingPathComponent("v1")
                        .appendingPathComponent("users")
                        .appendingPathComponent(userId)
                        .appendingPathComponent("lifecycle")
                        .appendingPathComponent("deactivate")

    let (_, deactivateResponse) = try await httpClient.send(
                        url: deactivateURL,
                        method: .post,
                        body: Data(),
                        headers: [
                            HttpClient.HeaderKey.accept: HttpClient.ContentType.json,
                            HttpClient.HeaderKey.contentType: HttpClient.ContentType.jsonUtf8,
                            HttpClient.HeaderKey.authorization: try oktaAuthorizationHeader()
                        ]
                    )

    if deactivateResponse.statusCode == 200 {
                        let deleteURL = oktaBaseURL
                            .appendingPathComponent("api")
                            .appendingPathComponent("v1")
                            .appendingPathComponent("users")
                            .appendingPathComponent(userId)

    let (_, deleteResponse) = try await httpClient.send(
                            url: deleteURL,
                            method: .delete,
                            body: Data(),
                            headers: [
                                HttpClient.HeaderKey.accept: HttpClient.ContentType.json,
                                HttpClient.HeaderKey.contentType: HttpClient.ContentType.jsonUtf8,
                                HttpClient.HeaderKey.authorization: try oktaAuthorizationHeader()
                            ]
                        )

    if deleteResponse.statusCode != 204 {
                            print("❌ Failed to delete Okta user (userId)")
                        }
                    } else {
                        print("❌ Failed to deactivate Okta user (userId)")
                    }
                } catch {
                    print("❌ Failed to clean up Okta user (userId): (error)")
                }
            }
        }
}
