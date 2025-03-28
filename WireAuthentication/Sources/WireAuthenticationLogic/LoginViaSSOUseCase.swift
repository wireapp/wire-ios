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

import AuthenticationServices
import Foundation
import WireAPI
import WireAuthenticationAPI

@MainActor
package struct LoginViaSSOUseCase: LoginViaSSOUseCaseProtocol {

    private let authenticationAPI: AuthenticationAPI
    private let baseURL: URL
    private let ssoCallbackURLScheme: String
    private let context = WebAuthPresentationContext()

    package init(
        authenticationAPI: AuthenticationAPI,
        baseURL: URL,
        ssoCallbackURLScheme: String
    ) {
        self.authenticationAPI = authenticationAPI
        self.baseURL = baseURL
        self.ssoCallbackURLScheme = ssoCallbackURLScheme
    }

    package func invoke(code: UUID?) async throws -> (userID: UUID, cookies: [HTTPCookie]) {
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

        return try await initiateWebAuth(
            url: url,
            verificationToken: verificationToken
        )
    }

    // MARK: Web auth URL

    /// Generates the URL for the SSO authentication screen
    ///
    /// - Parameters:
    ///   - ssoCode: SSO code
    /// - Returns: URL to the SSO authentication screen

    private func buildSSOLink(ssoCode: UUID) async throws -> (URL, SSOLoginVerificationToken) {
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
            URLQueryItem(
                name: URLQueryItem.Key.errorRedirect,
                value: errorCallback
            )
        ]

        guard let url = components.url else {
            throw LoginViaSSOUseCaseError.invalidURL
        }

        //validationToken.store(in: userDefaults)
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
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: ssoCallbackURLScheme
            ) { callbackURL, error in
                if let callbackURL {
                    let result = parseCallbackURL(
                        callbackURL,
                        verificationToken: verificationToken
                    )
                    continuation.resume(with: result)
                } else if let error = error as? ASWebAuthenticationSessionError {
                    switch error.code {
                    case .canceledLogin:
                        continuation.resume(throwing: LoginViaSSOUseCaseError.userCancelled)
                    case .presentationContextNotProvided:
                        continuation.resume(throwing: LoginViaSSOUseCaseError.contextNotProvided)
                    case .presentationContextInvalid:
                        continuation.resume(throwing: LoginViaSSOUseCaseError.invalidContext)
                    @unknown default:
                        // TODO: log
                        continuation.resume(throwing: LoginViaSSOUseCaseError.unknown)
                    }
                } else if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(throwing: LoginViaSSOUseCaseError.unknown)
                }
            }

            // Prevents cookie persistence.
            session.prefersEphemeralWebBrowserSession = true
            session.presentationContextProvider = context
            session.start()
        }
    }

    private func parseCallbackURL(
        _ url: URL,
        verificationToken: SSOLoginVerificationToken
    ) -> Result<(UUID, [HTTPCookie]), any Error> {
        guard
            let components = URLComponents(string: url.absoluteString),
            components.host == URL.Host.login,
            components.scheme == ssoCallbackURLScheme
        else {
            return .failure(LoginViaSSOUseCaseError.invalidCallbackURL)
        }

        let pathComponents = url.pathComponents

        guard url.pathComponents.count >= 2 else {
            return .failure(LoginViaSSOUseCaseError.invalidCallbackURL)
        }

        switch pathComponents[1] {
        case URL.Path.success:
            guard validateCallback(
                with: components,
                verificationToken: verificationToken
            ) else {
                return .failure(LoginViaSSOUseCaseError.callbackURLValidationFailed)
            }

            guard let cookieString = components.query(for: URLQueryItem.Key.cookie) else {
                return .failure(LoginViaSSOUseCaseError.invalidCallbackURL)
            }

            guard
                let rawUserID = components.query(for: URLQueryItem.Key.userIdentifier),
                let userID = UUID(uuidString: rawUserID)
            else {
                return .failure(LoginViaSSOUseCaseError.invalidCallbackURL)
            }

            let cookies = HTTPCookie.cookies(
                withResponseHeaderFields: ["Set-Cookie": cookieString],
                for: url
            )

            guard !cookies.isEmpty else {
                return .failure(LoginViaSSOUseCaseError.missingCookies)
            }

            return .success((userID, cookies))

        case URL.Path.failure:
            guard validateCallback(
                with: components,
                verificationToken: verificationToken
            ) else {
                return .failure(LoginViaSSOUseCaseError.callbackURLValidationFailed)
            }

            guard let label = components.query(for: URLQueryItem.Key.errorLabel) else {
                return .failure(LoginViaSSOUseCaseError.invalidCallbackURL)
            }

            return .failure(LoginViaSSOUseCaseError.authenticationFailed(SAMLError(label)))

        default:
            return .failure(LoginViaSSOUseCaseError.invalidCallbackURL)
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

private final class WebAuthPresentationContext: NSObject, ASWebAuthenticationPresentationContextProviding {

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        ASPresentationAnchor()
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
