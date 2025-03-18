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
    private let defaults: UserDefaults

    /// `SSOLinkGenerator` initializer with given parameters.
    /// - Parameters:
    ///   - authenticationAPI: `AuthenticationAPI` instance.
    ///   - baseURL: Backend URL.
    ///   - callbackScheme: The URL scheme that where the callback will be provided.
    ///   - defaults: The user defaults for storing temporary token.
    package init(
        authenticationAPI: AuthenticationAPI,
        baseURL: URL,
        callbackScheme: String,
        defaults: UserDefaults
    ) {
        self.authenticationAPI = authenticationAPI
        self.baseURL = baseURL
        self.callbackScheme = callbackScheme
        self.defaults = defaults
    }

    package func generateSSOLink(ssoCode: UUID) async throws -> URL {
        do {
            try await authenticationAPI.validateLoginToken(ssoCode: ssoCode)
        } catch AuthenticationAPIError.SSOLoginError.invalidSSOCode {
            throw SSOLinkGeneratorFailure.invalidSSOCode
        }

        return try await buildSSOLink(ssoCode: ssoCode)
    }

    package func flushToken() {
        SSOLoginVerificationToken.flush(in: defaults)
    }

    /// Generates the URL for the SSO authentication screen
    ///
    /// - Parameters:
    ///   - ssoCode: SSO code
    /// - Returns: URL to the SSO authentication screen
    func buildSSOLink(ssoCode: UUID) async throws -> URL {
        let validationToken = SSOLoginVerificationToken()
        var components = URLComponents()
        components.scheme = "https"
        components.host = baseURL.host
        components.path = "/sso/initiate-login/\(ssoCode.uuidString)"

        let successCallback = try makeSuccessCallbackString(using: validationToken)
        let errorCallback = try makeFailureCallbackString(using: validationToken)

        components.queryItems = [
            URLQueryItem(
                name: URLQueryItem.Key.successRedirect,
                value: successCallback
            ),
            URLQueryItem(name: URLQueryItem.Key.errorRedirect, value: errorCallback)
        ]

        guard let url = components.url else {
            throw SSOLinkGeneratorFailure.invalidSSOURL
        }

        validationToken.store(in: defaults)
        return url
    }

    private func makeSuccessCallbackString(using token: SSOLoginVerificationToken) throws -> String {
        var components = URLComponents()
        components.scheme = callbackScheme
        components.host = URL.Host.login
        components.path = "/" + URL.Path.success

        components.queryItems = [
            URLQueryItem(name: URLQueryItem.Key.cookie, value: URLQueryItem.Template.cookie),
            URLQueryItem(name: URLQueryItem.Key.userIdentifier, value: URLQueryItem.Template.userIdentifier),
            URLQueryItem(name: URLQueryItem.Key.validationToken, value: token.uuid.uuidString.lowercased())
        ]

        guard let url = components.url else {
            throw SSOLinkGeneratorFailure.invalidSSOURL
        }

        return url.absoluteString
    }

    private func makeFailureCallbackString(using token: SSOLoginVerificationToken) throws -> String {
        var components = URLComponents()
        components.scheme = callbackScheme
        components.host = URL.Host.login
        components.path = "/" + URL.Path.failure

        components.queryItems = [
            URLQueryItem(name: URLQueryItem.Key.errorLabel, value: URLQueryItem.Template.errorLabel),
            URLQueryItem(name: URLQueryItem.Key.validationToken, value: token.uuid.uuidString.lowercased())
        ]

        guard let url = components.url else {
            throw SSOLinkGeneratorFailure.invalidSSOURL
        }

        return url.absoluteString
    }

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
