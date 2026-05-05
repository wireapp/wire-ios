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
import OktaSdk
import WireNetwork

@MainActor
final class SSOHelper {
    private let userHelper: UserHelper
    private let httpClient: HttpClient
    private let oktaBaseURL: URL

    private var oktaApplicationId: String?
    private var oktaUserIds: [String] = []
    private var oktaClient: OktaClient?
    private(set) var identityProviderId: String?

    init(
        userHelper: UserHelper = UserHelper.default,
        httpClient: HttpClient = HttpClient(),
        oktaBaseURL: URL = .init(string: "https://dev-500508.oktapreview.com")!
    ) {
        self.userHelper = userHelper
        self.httpClient = httpClient
        self.oktaBaseURL = oktaBaseURL
    }

    @discardableResult
    func createSSOUserAsSelf(user: UserInfo) async throws -> UserInfo {
        let owner = try await createSSOUserForOkta(user: user)
        return try await addUserToOkta(user: owner)
    }

    @discardableResult
    func createSSOUser(owner: UserInfo, ssoUser: UserInfo) async throws -> UserInfo {
        _ = try await createSSOUserForOkta(user: owner)
        return try await addUserToOkta(user: ssoUser)
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
    func addUserToOkta(user: UserInfo) async throws -> UserInfo {
        user.password = "SSO\(user.password)"
        user.name = user.email
        user.isSSOUser = true

        let oktaUserId = try await createOktaUser(
            name: user.name,
            email: user.email,
            password: user.password
        )

        if oktaApplicationId != nil {
            try await assignUserToApplication(userId: oktaUserId)
        }
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

    @discardableResult
    func createOktaApplication(label: String, finalizeURL: String) async throws -> String {
        let application = SamlApplication(
            label: label,
            signOnMode: .saml20,
            visibility: ApplicationVisibility(autoSubmitToolbar: false),
            credentials: ApplicationCredentials(
                userNameTemplate: ApplicationCredentialsUsernameTemplate(
                    template: "${fn:substringBefore(source.login, \"@\")}",
                    type: "BUILT_IN"
                )
            ),
            settings: SamlApplicationSettings(
                signOn: SamlApplicationSettingsSignOn(
                    assertionSigned: true,
                    audience: finalizeURL,
                    authnContextClassRef: "urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport",
                    destination: finalizeURL,
                    digestAlgorithm: "SHA256",
                    honorForceAuthn: true,
                    idpIssuer: "https://www.okta.com/${org.externalKey}",
                    recipient: finalizeURL,
                    requestCompressed: false,
                    responseSigned: true,
                    signatureAlgorithm: "RSA_SHA256",
                    ssoAcsUrl: finalizeURL,
                    subjectNameIdFormat: "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress",
                    subjectNameIdTemplate: "${user.email}"
                )
            )
        )

        let data = try JSONEncoder().encode(application)

        let (responseData, response) = try await sendOktaRequest(
            path: ["apps"],
            method: .post,
            body: data
        )

        guard response.statusCode == 200 else {
            throw RuntimeError(
                "createOktaApplication failed: HTTP \(response.statusCode) \(String(data: responseData, encoding: .utf8) ?? "")"
            )
        }

        let object = try JSONSerialization.jsonObject(with: responseData, options: [])
        guard let json = object as? [String: Any],
              let applicationId = json["id"] as? String else {
            throw RuntimeError("createOktaApplication: failed to parse application id")
        }

        oktaApplicationId = applicationId

        let everyoneGroupId = try await fetchGroupId(named: "Everyone")
        try await assignApplicationToGroup(applicationId: applicationId, groupId: everyoneGroupId)
        try await waitForAppGroupLink(applicationId: applicationId, groupId: everyoneGroupId)

        return applicationId
    }

    func fetchGroupId(named groupName: String) async throws -> String {
        let groups = try await oktaSDKClient()
            .group
            .listGroups(q: groupName, limit: 100)
            .result

        if let group = groups.first(where: { $0.profile?.name == groupName }),
           let id = group.id {
            return id
        }

        throw RuntimeError("fetchGroupId: group not found: \(groupName)")
    }

    func assignApplicationToGroup(applicationId: String, groupId: String) async throws {
        _ = try await oktaSDKClient()
            .application
            .createApplicationGroupAssignment(
                appId: applicationId,
                groupId: groupId,
                applicationGroupAssignment: ApplicationGroupAssignment()
            )
    }

    private func waitForAppGroupLink(applicationId: String, groupId: String) async throws {
        for _ in 0 ..< 30 {
            do {
                _ = try await oktaSDKClient()
                    .application
                    .getApplicationGroupAssignment(appId: applicationId, groupId: groupId)
                return
            } catch {
                // ignore
            }

            try await Task.sleep(for: .seconds(0.7))
        }

        throw RuntimeError("waitForAppGroupLink: timed out")
    }

    func getOktaApplicationMetadata() async throws -> String {
        guard let oktaApplicationId else {
            throw RuntimeError("getOktaApplicationMeta oktaApplicationId is nil")
        }

        let url = oktaURL(path: ["apps", oktaApplicationId, "sso", "saml", "metadata"])

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
            throw RuntimeError("getOktaApplicationMeta empty response")
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
        let profile = UserProfile(
            email: email,
            firstName: name,
            lastName: name,
            login: email
        )

        let credentials = UserCredentials(
            password: PasswordCredential(value: password),
            recoveryQuestion: RecoveryQuestionCredential(
                answer: "fortytwo",
                question: "What is the answer to life, the universe and everything?"
            )
        )

        let request = CreateUserRequest(
            credentials: credentials,
            profile: profile
        )

        let user = try await oktaSDKClient()
            .user
            .createUser(body: request, activate: true)
            .result

        guard let id = user.id else {
            throw RuntimeError("createOktaUser: failed to parse Okta user id")
        }

        oktaUserIds.append(id)
        return id
    }

    func assignUserToApplication(userId: String) async throws {
        guard let oktaApplicationId else {
            throw RuntimeError("assignUserToApplication: oktaApplicationId is nil")
        }

        _ = try await oktaSDKClient()
            .application
            .assignUserToApplication(
                appId: oktaApplicationId,
                appUser: AppUser(id: userId)
            )
    }

    func getSSOCode() throws -> String {
        guard let identityProviderId else {
            throw RuntimeError("getSSOCode: identityProviderId is nil")
        }
        return "wire-\(identityProviderId)"
    }

    func cleanUpOktaResources() async {
        if let appId = oktaApplicationId {
            await cleanUpOktaApplication(appId)
            oktaApplicationId = nil
        }

        for userId in oktaUserIds {
            await cleanUpOktaUser(userId)
        }
        oktaUserIds.removeAll()
    }

    private func cleanUpOktaApplication(_ appId: String) async {
        do {
            let applicationClient = try oktaSDKClient().application
            try await applicationClient.deactivateApplication(appId: appId)
            try await applicationClient.deleteApplication(appId: appId)
        } catch {
            print("❌ Failed to clean up Okta application \(appId): \(error)")
        }
    }

    private func cleanUpOktaUser(_ userId: String) async {
        do {
            let userClient = try oktaSDKClient().user
            try await userClient.deactivateUser(userId: userId, sendEmail: false)
            try await userClient.deactivateOrDeleteUser(userId: userId, sendEmail: false)
        } catch {
            print("❌ Failed to clean up Okta user \(userId): \(error)")
        }
    }

    private func sendOktaRequest(
        path: [String],
        method: HttpClient.Method,
        body: Data
    ) async throws -> (Data, HTTPURLResponse) {
        let url = oktaURL(path: path)
        return try await httpClient.send(
            url: url,
            method: method,
            body: body,
            headers: try oktaJSONHeaders()
        )
    }

    private func oktaURL(path: [String]) -> URL {
        path.reduce(
            oktaBaseURL
                .appendingPathComponent("api")
                .appendingPathComponent("v1")
        ) { partialURL, component in
            partialURL.appendingPathComponent(component)
        }
    }

    private func oktaJSONHeaders() throws -> [String: String] {
        [
            HttpClient.HeaderKey.accept: HttpClient.ContentType.json,
            HttpClient.HeaderKey.contentType: HttpClient.ContentType.jsonUtf8,
            HttpClient.HeaderKey.authorization: try oktaAuthorizationHeader()
        ]
    }

    private func oktaSDKClient() throws -> OktaClient {
        if let oktaClient {
            return oktaClient
        }

        guard var domain = oktaBaseURL.host else {
            throw RuntimeError("Invalid Okta base URL: \(oktaBaseURL)")
        }

        if let port = oktaBaseURL.port {
            domain += ":\(port)"
        }

        let client = OktaClient(
            configuration: .init(
                apiKey: try oktaAPIKey(),
                domain: domain
            )
        )
        oktaClient = client
        return client
    }

    private func oktaAPIKey() throws -> String {
        let apiKey = ProcessInfo.processInfo.environment["OKTA_API_KEY_IOS"]?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let apiKey, !apiKey.isEmpty else {
            throw RuntimeError("Missing OKTA_API_KEY_IOS")
        }

        return apiKey
    }

    private func oktaAuthorizationHeader() throws -> String {
        "SSWS \(try oktaAPIKey())"
    }

    private func getFinalizeURLDependingOnBackend() -> String {
        let backend = userHelper.backendURL.absoluteString
        let sanitizedBackend = backend.hasSuffix("/") ? String(backend.dropLast()) : backend
        return sanitizedBackend + "/sso/finalize-login"
    }
}
