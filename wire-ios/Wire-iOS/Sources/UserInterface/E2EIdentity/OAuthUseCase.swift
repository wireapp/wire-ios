//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

import AppAuth
import Foundation
import WireRequestStrategy
import WireSystem
import WireUtilities

protocol OAuthUseCaseInterface {

    func invoke(parameters: OAuthParameters) async throws -> OAuthResponse

}

class OAuthUseCase: OAuthUseCaseInterface {

    private let logger = WireLogger.e2ei
    private var currentAuthorizationFlow: OIDExternalUserAgentSession?
    private var targetViewController: () -> UIViewController

    init(targetViewController: @escaping () -> UIViewController) {
        self.targetViewController = targetViewController
    }

    func invoke(parameters: OAuthParameters) async throws -> OAuthResponse {
        logger.info("invoke authentication flow")

        guard let redirectURI = URL(string: "wire://e2ei/oauth2redirect") else {
            throw OAuthError.missingRequestParameters
        }

        let request: OIDAuthorizationRequest = try await withCheckedThrowingContinuation { continuation in
            OIDAuthorizationService.discoverConfiguration(forIssuer: parameters.identityProvider) { configuration, error in
                if let error {
                    return continuation.resume(throwing: OAuthError.failedToRetrieveConfiguration(error))
                }

                guard let config = configuration else {
                    return continuation.resume(throwing: OAuthError.missingServiceConfiguration)
                }

                let claims = self.createAdditionalParameters(
                    with: parameters.keyauth,
                    acmeAudience: parameters.acmeAudience)

                let request = OIDAuthorizationRequest(
                    configuration: config,
                    clientId: parameters.clientID,
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
    private func execute(authorizationRequest: OIDAuthorizationRequest) async throws -> OAuthResponse {
        guard let userAgent = OIDExternalUserAgentIOS(
            presenting: targetViewController(),
            prefersEphemeralSession: true
        ) else {
            throw OAuthError.missingOIDExternalUserAgent
        }

        return try await withCheckedThrowingContinuation { [weak self] continuation in
            self?.currentAuthorizationFlow = OIDAuthState.authState(byPresenting: authorizationRequest,
                                                                    externalUserAgent: userAgent,
                                                                    callback: { authState, error in
                if let error = error as NSError? {
                    if error.domain == OIDGeneralErrorDomain, error.code == OIDErrorCode.userCanceledAuthorizationFlow.rawValue {
                        return continuation.resume(throwing: OAuthError.userCancelled)
                    } else {
                        return continuation.resume(throwing: OAuthError.failedToSendAuthorizationRequest(error))
                    }
                }

                guard let idToken = authState?.lastTokenResponse?.idToken else {
                    return continuation.resume(throwing: OAuthError.missingIdToken)
                }

                let refreshToken = authState?.lastTokenResponse?.refreshToken

                return continuation.resume(returning: OAuthResponse(idToken: idToken, refreshToken: refreshToken))
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
    case userCancelled

}
