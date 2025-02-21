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
import WireAPI
import WireAuthenticationAPI

package final class SSOLinkGenerator: SSOLinkGeneratorProtocol {

    private let authenticationAPI: AuthenticationAPI
    private let baseURL: URL
    private let callbackScheme: String

    package init(
        authenticationAPI: AuthenticationAPI,
        baseURL: URL,
        callbackScheme: String
    ) {
        self.authenticationAPI = authenticationAPI
        self.baseURL = baseURL
        self.callbackScheme = callbackScheme
    }

    package func generateSSOLink(ssoCode: UUID) async throws -> URL {
        try await authenticationAPI.validateLoginToken(ssoCode: ssoCode)
        return try await buildSSOLink(baseURL: baseURL, ssoCode: ssoCode, callbackScheme: callbackScheme)
    }

    /// Generate the link to the SSO authentication screen
    ///
    /// - Parameters:
    ///   - baseURL: Backend URL.
    ///   - ssoCode: SSO code
    ///   - callbackScheme: The URL scheme that where the callback will be provided.
    /// - Returns: URL to the SSO authentication screen
    @MainActor
    private func buildSSOLink(baseURL: URL, ssoCode: UUID, callbackScheme: String) async throws -> URL {
        let validationToken = CompanyLoginVerificationToken()
        var components = URLComponents()
        components.scheme = "https"
        components.host = baseURL.host
        components.path = "/sso/initiate-login/\(ssoCode.uuidString)"

        let successCallback = makeSuccessCallbackString(using: validationToken)
        let errorCallback = makeFailureCallbackString(using: validationToken)

        components.queryItems = [
            URLQueryItem(
                name: URLQueryItem.Key.successRedirect,
                value: successCallback
            ),
            URLQueryItem(name: URLQueryItem.Key.errorRedirect, value: errorCallback)
        ]

        guard let url = components.url else {
            throw LoginViaSSOViewModelFailure.invalidSSOURL
        }

        validationToken.store()
        print(validationToken.uuid.uuidString)
        return url
    }

    private func makeSuccessCallbackString(using token: CompanyLoginVerificationToken) -> String {
        var components = URLComponents()
        components.scheme = callbackScheme
        components.host = URL.Host.login
        components.path = "/" + URL.Path.success

        components.queryItems = [
            URLQueryItem(name: URLQueryItem.Key.cookie, value: URLQueryItem.Template.cookie),
            URLQueryItem(name: URLQueryItem.Key.userIdentifier, value: URLQueryItem.Template.userIdentifier),
            URLQueryItem(name: URLQueryItem.Key.validationToken, value: token.uuid.uuidString.lowercased())
        ]

        return components.url!.absoluteString
    }

    private func makeFailureCallbackString(using token: CompanyLoginVerificationToken) -> String {
        var components = URLComponents()
        components.scheme = callbackScheme
        components.host = URL.Host.login
        components.path = "/" + URL.Path.failure

        components.queryItems = [
            URLQueryItem(name: URLQueryItem.Key.errorLabel, value: URLQueryItem.Template.errorLabel),
            URLQueryItem(name: URLQueryItem.Key.validationToken, value: token.uuid.uuidString.lowercased())
        ]

        return components.url!.absoluteString
    }

}

package enum LoginViaSSOViewModelFailure: Error, Equatable {

    /// Invalid company login URL

    case invalidSSOURL

    case unknown

}

private extension URL {

    enum Host {
        static let login = "login"
    }

    enum Path {
        static let success = "success"
        static let failure = "failure"
    }

}

private extension URLQueryItem {

    enum Key {
        static let successRedirect = "success_redirect"
        static let errorRedirect = "error_redirect"
        static let cookie = "cookie"
        static let userIdentifier = "userid"
        static let errorLabel = "label"
        static let validationToken = "validation_token"
    }

    enum Template {
        static let cookie = "$cookie"
        static let userIdentifier = "$userid"
        static let errorLabel = "$label"
    }

}

public struct CompanyLoginVerificationToken: Codable, Equatable {

    /// The unique identifier of the token.
    let uuid: UUID
    /// The creation date of the token.
    let creationDate: Date
    /// The amount of seconds the token should be considered valid.
    let timeToLive: TimeInterval

    /// Creates a new validation token with an expiration time
    /// of 30 minutes if not specified otherwise.
    init(uuid: UUID = .init(), creationDate: Date = .init(), timeToLive: TimeInterval = 60 * 30) {
        self.uuid = uuid
        self.creationDate = creationDate
        self.timeToLive = timeToLive
    }

    /// Whether the token is no langer valid (older than its time to live).
    var isExpired: Bool {
        abs(creationDate.timeIntervalSinceNow) >= timeToLive
    }

    /// Validates a passed in UUID against the token.
    /// - parameter identifier: The uuid which should be validated against the token.
    /// - returns: Whether the UUID matches the token and the token is still valid.
    func matches(identifier: UUID) -> Bool {
        uuid == identifier && !isExpired
    }
}

public extension CompanyLoginVerificationToken {

    private static let defaultsKey = "CompanyLoginVerificationTokenDefaultsKey"

    /// Stores the token in the provided defaults.
    /// - parameter defaults: The defaults to store the token in.
    /// - returns: Whether the write operation succeeded.
    @discardableResult
    func store() -> Bool {
        do {
            let data = try JSONEncoder().encode(self)
            let wireGroupId = "com.wearezeta.zclient.alpha"
            let use = UserDefaults(suiteName: "group.\(wireGroupId)")
            //UserDefaults.setValue(data, forKey: CompanyLoginVerificationToken.defaultsKey)
            UserDefaults.standard.set(data, forKey: CompanyLoginVerificationToken.defaultsKey)
            use?.set(data, forKey: CompanyLoginVerificationToken.defaultsKey)
            //defaults.set(data, forKey: CompanyLoginVerificationToken.defaultsKey)
            return true
        } catch {
            return false
        }
    }

}
