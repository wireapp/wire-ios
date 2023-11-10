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
import WireUtilities
import AppAuthCore
import AppAuth

let logger = WireLogger(tag: "end-to-end-identity")

/// The `OAuthAuthenticationInterface`provides the display name and handle included in the identity token.
/// The client uses the authorization endpoint
/// and the token endpoint on the identity provider (IdP) to get the identity token.

public protocol OAuthAuthenticationInterface {

    /// Obtain the identity token from the custom issuer/identity provider (IdP).
    func getIdToken(from identityProvider: URL) async throws -> String?

}

public class OAuthAuthentication: OAuthAuthenticationInterface {

    weak var delegate: OIDAuthorizationDelegate?

    public func getIdToken(from identityProvider: URL) async throws -> String? {

        return try await withCheckedThrowingContinuation { continuation in
            getIdToken(from: identityProvider, delegate: delegate) { result in
                switch result {
                case .success(let token):
                    continuation.resume(returning: token)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

}

private extension OAuthAuthentication {

    typealias Result = Swift.Result<String?, Error>

    func getIdToken(from issuer: URL,
                    delegate: OIDAuthorizationDelegate?,
                    completion: @escaping (Result) -> Void) {

        guard let bundleID = Bundle.main.bundleIdentifier,
              let redirectURI = URL(string: "\(bundleID):/oauth2redirect"),
              let clientID = Bundle.idPClientID
        else {
            return
        }
        OIDAuthorizationService.discoverConfiguration(forIssuer: issuer) { [weak self] configuration, error in
            guard let config = configuration else {
                logger.error("Error retrieving discovery document: \(error?.localizedDescription ?? "Unknown error")")

                return completion(.failure(OAuthAuthenticationError.failedToRetrieveDiscoveryDocument))
            }

            let request = OIDAuthorizationRequest(configuration: config,
                                                  clientId: clientID,
                                                  clientSecret: nil,
                                                  scopes: [OIDScopeOpenID, OIDScopeProfile, OIDScopeEmail],
                                                  redirectURL: redirectURI,
                                                  responseType: OIDResponseTypeCode,
                                                  additionalParameters: nil)

            self?.execute(authorizationRequest: request,
                          delegate: delegate,
                          completion: completion)
        }
    }

    func execute(authorizationRequest: OIDAuthorizationRequest,
                 delegate: OIDAuthorizationDelegate?,
                 completion: @escaping (Result) -> Void) {

        guard let agent = delegate?.externalUserAgent else {
            logger.error("Fail to get external user agent")
            return
        }

        delegate?.currentAuthorizationFlow = OIDAuthState.authState(byPresenting: authorizationRequest,
                                                                    externalUserAgent: agent,
                                                                    callback: { authState, error in
            guard error == nil else {
                logger.error("Error sending request: \(error?.localizedDescription ?? "Unknown error")")

                return completion(.failure(OAuthAuthenticationError.failedToSendRequest))
            }

            /// Performing userinfo request
            authState?.performAction { (_, idToken, error) in
                guard error == nil else {
                    logger.error("Error sending request: \(error?.localizedDescription ?? "Unknown error")")

                    return completion(.failure(OAuthAuthenticationError.failedToSendRequest))
                }

                completion(.success(idToken))
            }
        })
    }

}

enum OAuthAuthenticationError: Error {

    case failedToSendRequest
    case failedToRetrieveDiscoveryDocument
    case unknown

}
