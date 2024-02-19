//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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
import AppAuth
import WireSystem
import WireUtilities
import WireRequestStrategy

public protocol OAuthUseCaseInterface {

    func invoke(
        for identityProvider: URL,
        clientID: String,
        keyauth: String,
        acmeAudience: String
    ) async throws -> (idToken: String, refreshToken: String)

}

public class OAuthUseCase: OAuthUseCaseInterface {

    private let logger = WireLogger.e2ei
    private var currentAuthorizationFlow: OIDExternalUserAgentSession?
    private var rootViewController: UIViewController

    init(rootViewController: UIViewController) {
        self.rootViewController = rootViewController
    }

    public func invoke(
        for identityProvider: URL,
        clientID: String,
        keyauth: String,
        acmeAudience: String
    ) async throws -> (idToken: String, refreshToken: String) {
        logger.info("invoke authentication flow")

        guard let bundleID = Bundle.main.bundleIdentifier,
              let redirectURI = URL(string: "\(bundleID):/oauth2redirect")
        else {
            throw OAuthError.missingRequestParameters
        }
        let request: OIDAuthorizationRequest = try await withCheckedThrowingContinuation { continuation in
            OIDAuthorizationService.discoverConfiguration(forIssuer: identityProvider) { configuration, error in
                if let error = error {
                    return continuation.resume(throwing: OAuthError.failedToRetrieveConfiguration(error))
                }

                guard let config = configuration else {
                    return continuation.resume(throwing: OAuthError.missingServiceConfiguration)
                }

                let claims = self.createAdditionalParameters(with: keyauth, acmeAudience: acmeAudience)

                let request = OIDAuthorizationRequest(configuration: config,
                                                      clientId: clientID,
                                                      scopes: [OIDScopeOpenID, OIDScopeProfile, OIDScopeEmail],
                                                      redirectURL: redirectURI,
                                                      responseType: OIDResponseTypeCode,
                                                      additionalParameters: claims)

                return continuation.resume(returning: request)
            }
        }

        return try await execute(authorizationRequest: request)
    }

    private func createAdditionalParameters(with keyauth: String, acmeAudience: String) -> [String: String]? {
        enum CodingKeys: String {
            case claims = "claims"
            case idToken = "id_token"
            case keyauth = "keyauth"
            case acmeAud = "acme_aud"
            case essential = "essential"
            case value = "value"
        }

        let keyauth: [String: Any] = [
            CodingKeys.essential.rawValue: true,
            CodingKeys.value.rawValue: "\(keyauth)"
        ]
        let acmeAud: [String: Any] = [
            CodingKeys.essential.rawValue: true,
            CodingKeys.value.rawValue: "\(acmeAudience)"
        ]
        let idToken = [
            CodingKeys.idToken.rawValue: [
                CodingKeys.keyauth.rawValue: keyauth,
                CodingKeys.acmeAud.rawValue: acmeAud
            ]
        ]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: idToken, options: .prettyPrinted),
              let idTokenString = String(bytes: jsonData, encoding: String.Encoding.utf8) else {
            return nil
        }

        return [CodingKeys.claims.rawValue: idTokenString]
    }

    @MainActor
    private func execute(authorizationRequest: OIDAuthorizationRequest) async throws -> (idToken: String, refreshToken: String) {
        guard let userAgent = OIDExternalUserAgentIOS(presenting: rootViewController) else {
            throw OAuthError.missingOIDExternalUserAgent
        }

        return try await withCheckedThrowingContinuation { [weak self] continuation in
            self?.currentAuthorizationFlow = OIDAuthState.authState(byPresenting: authorizationRequest,
                                                                    externalUserAgent: userAgent,
                                                                    callback: { authState, error in
                if let error = error {
                    return continuation.resume(throwing: OAuthError.failedToSendAuthorizationRequest(error))
                }

                guard let idToken = authState?.lastTokenResponse?.idToken else {
                    return continuation.resume(throwing: OAuthError.missingIdToken)
                }

                guard let refreshToken = authState?.lastTokenResponse?.refreshToken else {
                    return continuation.resume(throwing: OAuthError.missingRefreshToken)
                }

                return continuation.resume(returning: (idToken, refreshToken))
            })
        }

    }
}

enum OAuthError: Error {

    case failedToSendAuthorizationRequest(_ underlyingError: Error)
    case failedToRetrieveConfiguration(_ underlyingError: Error)
    case missingRequestParameters
    case missingServiceConfiguration
    case missingOIDExternalUserAgent
    case missingIdToken
    case missingRefreshToken

}
