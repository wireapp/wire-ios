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
//        case missingOktaApiKey
        case missingSSOClaimedUserEmail
        case missingSSOClaimedUserPassword
        case missingSSOClaimedDomainCode

        var errorDescription: String? {
            switch self {
            case .missingBackendURL: "Missing env var: BACKEND_URL"
            case .missingInbucketURL: "Missing env var: INBUCKET_URL / ANTA_INBUCKET_URL / BELLA_INBUCKET_URL"
            case .missingInbucketUsername: "Missing env var: INBUCKET_USERNAME"
            case .missingInbucketPassword: "Missing env var: INBUCKET_PASSWORD"
            case .missingDeepLinkURL: "Missing env var: ANTA_DEEPLINK_URL / BELLA_DEEPLINK_URL"
            case .missingCallingServiceURL: "Missing env var: CALLINGSERVICE_URL"
            case .missingCallingServiceUsername: "Missing env var: CALLINGSERVICE_USERNAME"
            case .missingCallingServicePassword: "Missing env var: CALLINGSERVICE_PASSWORD"
            case .missingCallingBackend: "Missing env var: PREDEFINED_BACKEND"
            case .missingCallingInstanceTypeName: "Missing env var: CALLING_INSTANCE_TYPE_NAME"
            case .missingCallingInstanceTypeVersion: "Missing env var: CALLING_INSTANCE_TYPE_VERSION"
//            case .missingOktaApiKey: "Missing env var: OKTA_API_KEY_IOS"
            case .missingSSOClaimedUserEmail: "Missing env var: SSO_CLAIMED_USER_EMAIL"
            case .missingSSOClaimedUserPassword: "Missing env var: SSO_CLAIMED_USER_PASSWORD"
            case .missingSSOClaimedDomainCode: "Missing env var: SSO_CLAIMED_DOMAIN_CODE"
            }
        }
    }

    private let stagingBackendURL: URL
    private let antaBackendURL: URL
    private let bellaBackendURL: URL

    private let stagingInbucketURL: URL
    private let antaInbucketURL: URL
    private let bellaInbucketURL: URL

    let antaDeepLinkURL: URL
    let bellaDeepLinkURL: URL

    let inbucketUsername: String
    let inbucketPassword: String
    let callingServiceURL: URL
    let callingServiceUsername: String
    let callingServicePassword: String
    let callingBackend: String
    let callingInstanceTypeName: String
    let callingInstanceTypeVersion: String
//    let oktaApiKey: String
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

        guard let antaDeeplinkURL = ProcessInfo.processInfo.environment["ANTA_DEEPLINK_URL"],
              !antaDeeplinkURL.isEmpty else {
            throw Failure.missingDeepLinkURL

        }
        guard let bellaDeeplinkURL = ProcessInfo.processInfo.environment["BELLA_DEEPLINK_URL"],
              !bellaDeeplinkURL.isEmpty else {
            throw Failure.missingDeepLinkURL

        }

        guard let antaInbucketURL = ProcessInfo.processInfo.environment["ANTA_INBUCKET_URL"],
              !antaInbucketURL.isEmpty else {
            throw Failure.missingInbucketURL
        }

        guard let bellaInbucketURL = ProcessInfo.processInfo.environment["BELLA_INBUCKET_URL"],
              !bellaInbucketURL.isEmpty else {
            throw Failure.missingInbucketURL
        }

        guard let backendURLAntaString = ProcessInfo.processInfo.environment["BACKEND_URL_ANTA"],
              !backendURLAntaString.isEmpty else {
            throw Failure.missingBackendURL
        }

        guard let backendURLBellaString = ProcessInfo.processInfo.environment["BACKEND_URL_BELLA"],
              !backendURLBellaString.isEmpty else {
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

//        guard let oktaApiKey = ProcessInfo.processInfo.environment["OKTA_API_KEY_IOS"],
//              !oktaApiKey.isEmpty else {
//            throw Failure.missingOktaApiKey
//        }

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
        self.antaDeepLinkURL = URL(string: "https://\(antaDeeplinkURL)")!
        self.antaInbucketURL = URL(string: "https://\(antaInbucketURL)")!
        self.antaBackendURL = URL(string: "https://\(backendURLAntaString)")!
        self.bellaDeepLinkURL = URL(string: "https://\(bellaDeeplinkURL)")!
        self.bellaInbucketURL = URL(string: "https://\(bellaInbucketURL)")!
        self.bellaBackendURL = URL(string: "https://\(backendURLBellaString)")!
        self.callingServiceURL = callingServiceEnvironment.url
        self.callingBackend = callingBackend
        self.callingInstanceTypeName = callingInstanceTypeName
        self.callingInstanceTypeVersion = callingInstanceTypeVersion
//        self.oktaApiKey = oktaApiKey
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
        case .anta:
            antaInbucketURL
        case .staging:
            stagingInbucketURL
        case .bella:
            bellaInbucketURL
        }
    }

    func backendURL(for target: BackendTarget) -> URL {
        switch target {
        case .anta:
            antaBackendURL
        case .staging:
            stagingBackendURL
        case .bella:
            bellaBackendURL
        }
    }

    func deepLinkURL(for target: BackendTarget) -> URL {
        switch target {
        case .anta:
            antaDeepLinkURL
        case .bella:
            bellaDeepLinkURL
        case .staging:
            fatalError("Not implemented yet")
        }
    }

}
