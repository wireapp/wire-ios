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
    private let userDefaults: UserDefaults

    private let context = WebAuthPresentationContext()

    package init(
        authenticationAPI: AuthenticationAPI,
        baseURL: URL,
        ssoCallbackURLScheme: String,
        userDefaults: UserDefaults
    ) {
        self.authenticationAPI = authenticationAPI
        self.baseURL = baseURL
        self.ssoCallbackURLScheme = ssoCallbackURLScheme
        self.userDefaults = userDefaults
    }

    package func invoke(code: UUID?) async throws -> (userID: UUID, cookies: [HTTPCookie]) {
        let ssoCode = if let code {
            code
        } else if let defaultCode = try await authenticationAPI.getSSOCode() {
            defaultCode
        } else {
            throw LoginViaSSOUseCaseError.noDefaultCodeAvailable
        }

        let url = try await generateSSOLink(ssoCode: ssoCode)
        return try await initiateWebAuth(url: url)
    }

    // MARK: Web auth URL

    private func generateSSOLink(ssoCode: UUID) async throws -> URL {
        do {
            try await authenticationAPI.validateLoginToken(ssoCode: ssoCode)
        } catch AuthenticationAPIError.SSOLoginError.invalidSSOCode {
            throw LoginViaSSOUseCaseError.invalidCode
        }

        return try await buildSSOLink(ssoCode: ssoCode)
    }


    /// Generates the URL for the SSO authentication screen
    ///
    /// - Parameters:
    ///   - ssoCode: SSO code
    /// - Returns: URL to the SSO authentication screen

    private func buildSSOLink(ssoCode: UUID) async throws -> URL {
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
            throw LoginViaSSOUseCaseError.invalidURL
        }

        validationToken.store(in: userDefaults)
        return url
    }

    private func makeSuccessCallbackString(using token: SSOLoginVerificationToken) throws -> String {
        var components = URLComponents()
        components.scheme = ssoCallbackURLScheme
        components.host = URL.Host.login
        components.path = "/" + URL.Path.success

        components.queryItems = [
            URLQueryItem(name: URLQueryItem.Key.cookie, value: URLQueryItem.Template.cookie),
            URLQueryItem(name: URLQueryItem.Key.userIdentifier, value: URLQueryItem.Template.userIdentifier),
            URLQueryItem(name: URLQueryItem.Key.validationToken, value: token.uuid.uuidString.lowercased())
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
            URLQueryItem(name: URLQueryItem.Key.errorLabel, value: URLQueryItem.Template.errorLabel),
            URLQueryItem(name: URLQueryItem.Key.validationToken, value: token.uuid.uuidString.lowercased())
        ]

        guard let url = components.url else {
            throw LoginViaSSOUseCaseError.invalidURL
        }

        return url.absoluteString
    }

    // MARK: Initiate web auth

    private func initiateWebAuth(url: URL) async throws -> (UUID, [HTTPCookie]) {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: ssoCallbackURLScheme
            ) { callbackURL, error in
                if let callbackURL {
                    continuation.resume(with: parseCallbackURL(callbackURL))
                } else if let error {
                    continuation.resume(throwing: error)
                } else {
                    // TODO: check the error
                    continuation.resume(throwing: LoginViaSSOUseCaseError.userCancelled)
                }
            }

            // Prevents cookie persistence.
            session.prefersEphemeralWebBrowserSession = true
            session.presentationContextProvider = context
            session.start()
        }
    }

    private func parseCallbackURL(_ url: URL) -> Result<(UUID, [HTTPCookie]), any Error> {
        defer {
            flushToken()
        }

        guard
            let components = URLComponents(string: url.absoluteString),
            let host = components.host,
            let scheme = components.scheme,
            scheme == ssoCallbackURLScheme
        else {
            // invalid callback
            fatalError()
        }

        switch host {
        case URL.Host.login:
            let pathComponents = url.pathComponents

            guard url.pathComponents.count >= 2 else {
                // invalid callback
                fatalError()
            }

            switch pathComponents[1] {
            case URL.Path.success:
                // TODO: handle
                try! validateCallback(with: components)

                guard let cookieString = components.query(for: URLQueryItem.Key.cookie) else {
                    // invalid callback
                    fatalError()
                }

                guard
                    let rawUserID = components.query(for: URLQueryItem.Key.userIdentifier),
                    let userID = UUID(uuidString: rawUserID)
                else {
                    // invalid callback
                    fatalError()
                }

                let cookies = HTTPCookie.cookies(
                    withResponseHeaderFields: ["Set-Cookie": cookieString],
                    for: url
                )

                guard !cookies.isEmpty else {
                    // invalid cookie
                    fatalError()
                }

                return .success((userID, cookies))

            case URL.Path.failure:
                // TODO: handle
                try! validateCallback(with: components)

                guard let label = components.query(for: URLQueryItem.Key.errorLabel) else {
                    // invalid callback
                    fatalError()
                }

                // TODO: fix this
                //throw CompanyLoginError(label: label)
                fatalError()

            default:
                // invalid callback
                fatalError()
            }

        default:
            // invalid callback
            fatalError()
        }
    }


    // MARK: Verification

    private func validateCallback(with components: URLComponents) throws {
        guard
            let storedToken = SSOLoginVerificationToken.current(in: userDefaults),
            let rawToken = components.query(for: URLQueryItem.Key.validationToken),
            let token = UUID(uuidString: rawToken),
            storedToken.matches(identifier: token)
        else {
            // validation failed
            fatalError()
        }
    }

    private func flushToken() {
        SSOLoginVerificationToken.flush(in: userDefaults)
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
