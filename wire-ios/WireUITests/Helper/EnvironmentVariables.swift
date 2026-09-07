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

struct EnvironmentVariables {
    enum Failure: LocalizedError {
        case missingBackendURL
        case missingInbucketURL
        case missingInbucketUsername
        case missingInbucketPassword
        case missingDeepLinkURL
        case missingCallingServiceURL
        case missingCallingServiceUsername
        case missingCallingServicePassword
        case missingCallingBackend
        case missingCallingInstanceTypeName
        case missingCallingInstanceTypeVersion
        case missingKeycloakURL
        case missingKeycloakAdminPassword
        case missingSSOClaimedUserEmail
        case missingSSOClaimedUserPassword
        case missingSSOClaimedDomainCode

        var errorDescription: String? {
            switch self {
            case .missingBackendURL: "Missing env var: BACKEND_URL"
            case .missingInbucketURL: "Missing env var: INBUCKET_URL / QA_FEDERATION_A_INBUCKET_URL / QA_FEDERATION_B_INBUCKET_URL"
            case .missingInbucketUsername: "Missing env var: INBUCKET_USERNAME"
            case .missingInbucketPassword: "Missing env var: INBUCKET_PASSWORD"
            case .missingDeepLinkURL: "Missing env var: QA_FEDERATION_A_DEEPLINK_URL / QA_FEDERATION_B_DEEPLINK_URL"
            case .missingCallingServiceURL: "Missing env var: CALLINGSERVICE_URL"
            case .missingCallingServiceUsername: "Missing env var: CALLINGSERVICE_USERNAME"
            case .missingCallingServicePassword: "Missing env var: CALLINGSERVICE_PASSWORD"
            case .missingCallingBackend: "Missing env var: PREDEFINED_BACKEND"
            case .missingCallingInstanceTypeName: "Missing env var: CALLING_INSTANCE_TYPE_NAME"
            case .missingCallingInstanceTypeVersion: "Missing env var: CALLING_INSTANCE_TYPE_VERSION"
            case .missingKeycloakURL: "Missing env var: KEYCLOAK_URL"
            case .missingKeycloakAdminPassword: "Missing env var: KEYCLOAK_ADMIN_PASSWORD"
            case .missingSSOClaimedUserEmail: "Missing env var: SSO_CLAIMED_USER_EMAIL"
            case .missingSSOClaimedUserPassword: "Missing env var: SSO_CLAIMED_USER_PASSWORD"
            case .missingSSOClaimedDomainCode: "Missing env var: SSO_CLAIMED_DOMAIN_CODE"
            }
        }
    }

    private let stagingBackendURL: URL
    private let qaFederationABackendURL: URL
    private let qaFederationBBackendURL: URL

    private let stagingInbucketURL: URL
    private let qaFederationAInbucketURL: URL
    private let qaFederationBInbucketURL: URL

    let qaFederationADeepLinkURL: URL
    let qaFederationBDeepLinkURL: URL

    let inbucketUsername: String
    let inbucketPassword: String
    let callingServiceURL: URL
    let callingServiceUsername: String
    let callingServicePassword: String
    let callingBackend: String
    let callingInstanceTypeName: String
    let callingInstanceTypeVersion: String
    let keycloakURL: URL
    let keycloakAdminPassword: String
    let ssoClaimedUserEmail: String
    let ssoClaimedUserPassword: String
    let ssoClaimedDomainCode: String

    init() throws {
        guard let backendURLString = ProcessInfo.processInfo.environment["BACKEND_URL"],
              !backendURLString.isEmpty else {
            throw Failure.missingBackendURL
        }
        guard let inbucketHostname = ProcessInfo.processInfo.environment["INBUCKET_URL"],
              !inbucketHostname.isEmpty else {
            throw Failure.missingInbucketURL
        }

        guard let inbucketUsername = ProcessInfo.processInfo.environment["INBUCKET_USERNAME"],
              !inbucketUsername.isEmpty else {
            throw Failure.missingInbucketUsername
        }

        guard let inbucketPassword = ProcessInfo.processInfo.environment["INBUCKET_PASSWORD"],
              !inbucketPassword.isEmpty else {
            throw Failure.missingInbucketPassword
        }

        guard let callingServiceURLString = ProcessInfo.processInfo.environment["CALLINGSERVICE_URL"],
              !callingServiceURLString.isEmpty else {
            throw Failure.missingCallingServiceURL
        }

        guard let callingServiceUsername = ProcessInfo.processInfo.environment["CALLINGSERVICE_USERNAME"],
              !callingServiceUsername.isEmpty else {
            throw Failure.missingCallingServiceUsername
        }

        guard let callingServicePassword = ProcessInfo.processInfo.environment["CALLINGSERVICE_PASSWORD"],
              !callingServicePassword.isEmpty else {
            throw Failure.missingCallingServicePassword
        }

        guard let qaFederationADeeplinkURL = ProcessInfo.processInfo.environment["QA_FEDERATION_A_DEEPLINK_URL"],
              !qaFederationADeeplinkURL.isEmpty else {
            throw Failure.missingDeepLinkURL

        }
        guard let qaFederationBDeeplinkURL = ProcessInfo.processInfo.environment["QA_FEDERATION_B_DEEPLINK_URL"],
              !qaFederationBDeeplinkURL.isEmpty else {
            throw Failure.missingDeepLinkURL

        }

        guard let qaFederationAInbucketURL = ProcessInfo.processInfo.environment["QA_FEDERATION_A_INBUCKET_URL"],
              !qaFederationAInbucketURL.isEmpty else {
            throw Failure.missingInbucketURL
        }

        guard let qaFederationBInbucketURL = ProcessInfo.processInfo.environment["QA_FEDERATION_B_INBUCKET_URL"],
              !qaFederationBInbucketURL.isEmpty else {
            throw Failure.missingInbucketURL
        }

        guard let backendURLQAFederationAString = ProcessInfo.processInfo.environment["BACKEND_URL_QA_FEDERATION_A"],
              !backendURLQAFederationAString.isEmpty else {
            throw Failure.missingBackendURL
        }

        guard let backendURLQAFederationBString = ProcessInfo.processInfo.environment["BACKEND_URL_QA_FEDERATION_B"],
              !backendURLQAFederationBString.isEmpty else {
            throw Failure.missingBackendURL
        }

        guard let callingBackend = ProcessInfo.processInfo.environment["PREDEFINED_BACKEND"],
              !callingBackend.isEmpty else {
            throw Failure.missingCallingBackend
        }

        guard let callingInstanceTypeName = ProcessInfo.processInfo.environment["CALLING_INSTANCE_TYPE_NAME"],
              !callingInstanceTypeName.isEmpty else {
            throw Failure.missingCallingInstanceTypeName
        }

        guard let callingInstanceTypeVersion = ProcessInfo.processInfo.environment["CALLING_INSTANCE_TYPE_VERSION"],
              !callingInstanceTypeVersion.isEmpty else {
            throw Failure.missingCallingInstanceTypeVersion
        }

        guard let keycloakURL = ProcessInfo.processInfo.environment["KEYCLOAK_URL"],
              !keycloakURL.isEmpty else {
            throw Failure.missingKeycloakURL
        }

        guard let keycloakAdminPassword = ProcessInfo.processInfo.environment["KEYCLOAK_ADMIN_PASSWORD"],
              !keycloakAdminPassword.isEmpty else {
            throw Failure.missingKeycloakAdminPassword
        }

        guard let ssoClaimedUserEmail = ProcessInfo.processInfo.environment["SSO_CLAIMED_USER_EMAIL"],
              !ssoClaimedUserEmail.isEmpty else {
            throw Failure.missingSSOClaimedUserEmail
        }

        guard let ssoClaimedUserPassword = ProcessInfo.processInfo.environment["SSO_CLAIMED_USER_PASSWORD"],
              !ssoClaimedUserPassword.isEmpty else {
            throw Failure.missingSSOClaimedUserPassword
        }

        guard let ssoClaimedDomainCode = ProcessInfo.processInfo.environment["SSO_CLAIMED_DOMAIN_CODE"],
              !ssoClaimedDomainCode.isEmpty else {
            throw Failure.missingSSOClaimedDomainCode
        }

        self.stagingBackendURL = URL(string: "https://\(backendURLString)")!
        self.stagingInbucketURL = URL(string: "https://\(inbucketHostname)")!
        self.inbucketUsername = inbucketUsername
        self.inbucketPassword = inbucketPassword
        let callingServiceEnvironment = Self.callingServiceEnvironment(
            defaultURLString: callingServiceURLString,
            defaultUsername: callingServiceUsername,
            defaultPassword: callingServicePassword
        )

        self.callingServiceUsername = callingServiceEnvironment.username
        self.callingServicePassword = callingServiceEnvironment.password
        self.qaFederationADeepLinkURL = URL(string: "https://\(qaFederationADeeplinkURL)")!
        self.qaFederationAInbucketURL = URL(string: "https://\(qaFederationAInbucketURL)")!
        self.qaFederationABackendURL = URL(string: "https://\(backendURLQAFederationAString)")!
        self.qaFederationBDeepLinkURL = URL(string: "https://\(qaFederationBDeeplinkURL)")!
        self.qaFederationBInbucketURL = URL(string: "https://\(qaFederationBInbucketURL)")!
        self.qaFederationBBackendURL = URL(string: "https://\(backendURLQAFederationBString)")!
        self.callingServiceURL = callingServiceEnvironment.url
        self.callingBackend = callingBackend
        self.callingInstanceTypeName = callingInstanceTypeName
        self.callingInstanceTypeVersion = callingInstanceTypeVersion
        self.keycloakURL = URL(string: "https://\(keycloakURL)")!
        self.keycloakAdminPassword = keycloakAdminPassword
        self.ssoClaimedUserEmail = ssoClaimedUserEmail
        self.ssoClaimedUserPassword = ssoClaimedUserPassword
        self.ssoClaimedDomainCode = ssoClaimedDomainCode
    }

    private static func callingServiceEnvironment(
        defaultURLString: String,
        defaultUsername: String,
        defaultPassword: String
    ) -> (url: URL, username: String, password: String) {
        let environment = ProcessInfo.processInfo.environment
        let isCI = environment["CI"]?.lowercased() == "true"

        if !isCI,
           let internalURLString = environment["CALLINGSERVICE_INTERNAL_URL"],
           let internalUsername = environment["CALLINGSERVICE_INTERNAL_USERNAME"],
           let internalPassword = environment["CALLINGSERVICE_INTERNAL_PASSWORD"],
           !internalURLString.isEmpty,
           !internalUsername.isEmpty,
           !internalPassword.isEmpty {
            return (
                url: callingServiceURL(from: internalURLString, defaultScheme: "http"),
                username: internalUsername,
                password: internalPassword
            )
        }

        return (
            url: callingServiceURL(from: defaultURLString, defaultScheme: "https"),
            username: defaultUsername,
            password: defaultPassword
        )
    }

    private static func callingServiceURL(from value: String, defaultScheme: String) -> URL {
        if value.contains("://") {
            URL(string: value)!
        } else {
            URL(string: "\(defaultScheme)://\(value)")!
        }
    }

    func inbucketURL(for target: BackendTarget) -> URL {
        switch target {
        case .qaFederationA:
            qaFederationAInbucketURL
        case .staging:
            stagingInbucketURL
        case .qaFederationB:
            qaFederationBInbucketURL
        }
    }

    func backendURL(for target: BackendTarget) -> URL {
        switch target {
        case .qaFederationA:
            qaFederationABackendURL
        case .staging:
            stagingBackendURL
        case .qaFederationB:
            qaFederationBBackendURL
        }
    }

    func deepLinkURL(for target: BackendTarget) -> URL {
        switch target {
        case .qaFederationA:
            qaFederationADeepLinkURL
        case .qaFederationB:
            qaFederationBDeepLinkURL
        case .staging:
            fatalError("Not implemented yet")
        }
    }

}
