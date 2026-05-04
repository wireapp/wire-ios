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

import AuthenticationServices
import Foundation
import WireAuthenticationAPI
import WireNetwork

@MainActor
package struct LoginViaSSOUseCase: LoginViaSSOUseCaseProtocol {

    private let authenticationAPI: AuthenticationAPI
    private let baseURL: URL
    private let ssoCallbackURLScheme: String
    private let verificationTokenGenerator: any SSOLoginVerificationTokenGeneratorProtocol
    private let webAuthenticator: any WebAuthenticatorProtocol
    private let createAuthResultUseCase: any CreateAuthenticationResultUseCaseProtocol

    package init(
        authenticationAPI: AuthenticationAPI,
        baseURL: URL,
        ssoCallbackURLScheme: String,
        verificationTokenGenerator: any SSOLoginVerificationTokenGeneratorProtocol,
        webAuthenticator: any WebAuthenticatorProtocol,
        createAuthResultUseCase: any CreateAuthenticationResultUseCaseProtocol
    ) {
        self.authenticationAPI = authenticationAPI
        self.baseURL = baseURL
        self.ssoCallbackURLScheme = ssoCallbackURLScheme
        self.verificationTokenGenerator = verificationTokenGenerator
        self.webAuthenticator = webAuthenticator
        self.createAuthResultUseCase = createAuthResultUseCase
    }

    package func invoke(code: UUID?) async throws -> AuthenticationResult {
        let ssoCode = if let code {
            code
        } else if let defaultCode = try await authenticationAPI.getSSOCode() {
            defaultCode
        } else {
            throw LoginViaSSOUseCaseError.noDefaultCodeAvailable
        }

        do {
            try await authenticationAPI.validateLoginToken(ssoCode: ssoCode)
        } catch AuthenticationAPIError.SSOLoginError.invalidSSOCode {
            throw LoginViaSSOUseCaseError.invalidCode
        }

        let (url, verificationToken) = try await buildSSOLink(ssoCode: ssoCode)

        let (userID, cookies) = try await initiateWebAuth(
            url: url,
            verificationToken: verificationToken
        )

        return try await createAuthResultUseCase.invoke(
            userID: userID,
            cookies: cookies,
            accessToken: nil,
            emailCredentials: nil
        )
    }

    // MARK: Web auth URL

    /// Generates the URL for the SSO authentication screen
    ///
    /// - Parameters:
    ///   - ssoCode: SSO code
    /// - Returns: URL to the SSO authentication screen

    private func buildSSOLink(ssoCode: UUID) async throws -> (URL, SSOLoginVerificationToken) {
        let validationToken = verificationTokenGenerator.generateToken()
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
            URLQueryItem(
                name: URLQueryItem.Key.errorRedirect,
                value: errorCallback
            )
        ]

        guard let url = components.url else {
            throw LoginViaSSOUseCaseError.invalidURL
        }

        return (url, validationToken)
    }

    private func makeSuccessCallbackString(using token: SSOLoginVerificationToken) throws -> String {
        var components = URLComponents()
        components.scheme = ssoCallbackURLScheme
        components.host = URL.Host.login
        components.path = "/" + URL.Path.success

        components.queryItems = [
            URLQueryItem(
                name: URLQueryItem.Key.cookie,
                value: URLQueryItem.Template.cookie
            ),
            URLQueryItem(
                name: URLQueryItem.Key.userIdentifier,
                value: URLQueryItem.Template.userIdentifier
            ),
            URLQueryItem(
                name: URLQueryItem.Key.validationToken,
                value: token.uuid.uuidString.lowercased()
            )
        ]

        guard let url = components.url else {
            throw LoginViaSSOUseCaseError.invalidURL
        }

        return url.absoluteString
    }

    private func makeFailureCallbackString(using token: SSOLoginVerificationToken) throws -> String {
        var components = URLComponents()
        components.scheme = ssoCallbackURLScheme
        components.host = URL.Host.login
        components.path = "/" + URL.Path.failure

        components.queryItems = [
            URLQueryItem(
                name: URLQueryItem.Key.errorLabel,
                value: URLQueryItem.Template.errorLabel
            ),
            URLQueryItem(
                name: URLQueryItem.Key.validationToken,
                value: token.uuid.uuidString.lowercased()
            )
        ]

        guard let url = components.url else {
            throw LoginViaSSOUseCaseError.invalidURL
        }

        return url.absoluteString
    }

    // MARK: Initiate web auth

    private func initiateWebAuth(
        url: URL,
        verificationToken: SSOLoginVerificationToken
    ) async throws -> (UUID, [HTTPCookie]) {
        let callbackURL: URL?
        do {
            callbackURL = try await webAuthenticator.authenticate(url: url)
        } catch let error as ASWebAuthenticationSessionError {
            switch error.code {
            case .canceledLogin:
                throw LoginViaSSOUseCaseError.userCancelled
            case .presentationContextNotProvided:
                throw LoginViaSSOUseCaseError.contextNotProvided
            case .presentationContextInvalid:
                throw LoginViaSSOUseCaseError.invalidContext
            @unknown default:
                throw LoginViaSSOUseCaseError.unknown
            }
        }

        guard let callbackURL else {
            throw LoginViaSSOUseCaseError.unknown
        }

        return try parseCallbackURL(
            callbackURL,
            verificationToken: verificationToken
        )
    }

    private func parseCallbackURL(
        _ url: URL,
        verificationToken: SSOLoginVerificationToken
    ) throws -> (UUID, [HTTPCookie]) {
        guard
            let components = URLComponents(string: url.absoluteString),
            components.host == URL.Host.login,
            components.scheme == ssoCallbackURLScheme
        else {
            throw LoginViaSSOUseCaseError.invalidCallbackURL
        }

        let pathComponents = url.pathComponents

        guard url.pathComponents.count >= 2 else {
            throw LoginViaSSOUseCaseError.invalidCallbackURL
        }

        switch pathComponents[1] {
        case URL.Path.success:
            guard validateCallback(
                with: components,
                verificationToken: verificationToken
            ) else {
                throw LoginViaSSOUseCaseError.callbackURLValidationFailed
            }

            guard let cookieString = components.query(for: URLQueryItem.Key.cookie) else {
                throw LoginViaSSOUseCaseError.invalidCallbackURL
            }

            guard
                let rawUserID = components.query(for: URLQueryItem.Key.userIdentifier),
                let userID = UUID(uuidString: rawUserID)
            else {
                throw LoginViaSSOUseCaseError.invalidCallbackURL
            }

            let cookies = HTTPCookie.cookies(
                withResponseHeaderFields: ["Set-Cookie": cookieString],
                for: url
            )

            guard !cookies.isEmpty else {
                throw LoginViaSSOUseCaseError.missingCookies
            }

            return (userID, cookies)

        case URL.Path.failure:
            guard validateCallback(
                with: components,
                verificationToken: verificationToken
            ) else {
                throw LoginViaSSOUseCaseError.callbackURLValidationFailed
            }

            guard let label = components.query(for: URLQueryItem.Key.errorLabel) else {
                throw LoginViaSSOUseCaseError.invalidCallbackURL
            }

            throw LoginViaSSOUseCaseError.authenticationFailed(SAMLError(label))

        default:
            throw LoginViaSSOUseCaseError.invalidCallbackURL
        }
    }

    // MARK: Verification

    private func validateCallback(
        with components: URLComponents,
        verificationToken: SSOLoginVerificationToken
    ) -> Bool {
        guard
            let rawToken = components.query(for: URLQueryItem.Key.validationToken),
            let token = UUID(uuidString: rawToken),
            verificationToken.matches(identifier: token)
        else {
            return false
        }

        return true
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

private extension URLComponents {

    func query(for key: String) -> String? {
        queryItems?.first(where: { $0.name == key })?.value
    }

}

private extension SAMLError {

    init(_ label: String) {
        switch label {
        case "server-error-unsupported-saml":
            self = .serverErrorUnsupportedSAML
        case "bad-success-redirect":
            self = .badSuccessRedirect
        case "bad-failure-redirect":
            self = .badFailureRedirect
        case "bad-username":
            self = .badUsername
        case "bad-upstream":
            self = .badUpstream
        case "server-error":
            self = .serverError
        case "not-found":
            self = .notFound
        case "forbidden":
            self = .forbidden
        case "no-matching-auth-req":
            self = .noMatchingAuthReq
        case "insufficient-permissions":
            self = .insufficientPermissions
        default:
            self = .unknown
        }
    }

    /// The code to display to the user inside alerts.

    var displayCode: String {
        switch self {
        case .unknown: "0"
        case .serverErrorUnsupportedSAML: "1"
        case .badSuccessRedirect: "2"
        case .badFailureRedirect: "3"
        case .badUsername: "4"
        case .badUpstream: "5"
        case .serverError: "6"
        case .notFound: "7"
        case .forbidden: "8"
        case .noMatchingAuthReq: "9"
        case .insufficientPermissions: "10"
        }
    }

}
