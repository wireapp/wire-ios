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

    func invoke(for identityProvider: URL) async throws -> IdToken

}

public class OAuthUseCase: OAuthUseCaseInterface {

    private let logger = WireLogger.e2ei
    private var currentAuthorizationFlow: OIDExternalUserAgentSession?
    private var rootViewController: UIViewController

    init(rootViewController: UIViewController) {
        self.rootViewController = rootViewController
    }

    /// keyAuth and acmeAudience
    public func invoke(for identityProvider: URL) async throws -> IdToken {
        logger.info("invoke authentication flow")

        guard let bundleID = Bundle.main.bundleIdentifier,
              let redirectURI = URL(string: "\(bundleID):/oauth2redirect")// ,
//              let clientID = Bundle.idPClientID,
//              let clientSecret = \Bundle.idPClientSecret
        else {
            throw OAuthError.missingRequestParameters
        }
        let clientID = ""
        let clientSecret = ""
        let request: OIDAuthorizationRequest = try await withCheckedThrowingContinuation { continuation in
            OIDAuthorizationService.discoverConfiguration(forIssuer: identityProvider) { configuration, error in
                if let error = error {
                    return continuation.resume(throwing: OAuthError.failedToRetrieveConfiguration(error))
                }

                guard let config = configuration else {
                    return continuation.resume(throwing: OAuthError.missingServiceConfiguration)
                }

                let request = OIDAuthorizationRequest(configuration: config,
                                                      clientId: clientID,
                                                      clientSecret: clientSecret,
                                                      scopes: [OIDScopeOpenID, OIDScopeProfile, OIDScopeEmail],
                                                      redirectURL: redirectURI,
                                                      responseType: OIDResponseTypeCode,
                                                      additionalParameters: nil)

                return continuation.resume(returning: request)
            }
        }

        return try await execute(authorizationRequest: request)
    }

    private func execute(authorizationRequest: OIDAuthorizationRequest) async throws -> IdToken {
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

                authState?.performAction { (_, idToken, error) in
                    if let error = error {
                        return continuation.resume(throwing: OAuthError.failedToSendAuthorizationRequest(error))
                    }

                    guard let idToken = idToken else {
                        return continuation.resume(throwing: OAuthError.missingIdToken)
                    }

                    return continuation.resume(returning: idToken)
                }
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

}
