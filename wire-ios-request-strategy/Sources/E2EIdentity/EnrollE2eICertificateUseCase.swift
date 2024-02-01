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

public typealias OAuthBlock = (_ idP: URL,
                               _ clientID: String,
                               _ keyauth: String,
                               _ acmeAud: String) async throws -> (String, String)

public protocol EnrollE2eICertificateUseCaseInterface {

    func invoke(e2eiClientId: E2eIClientID,
                userName: String,
                userHandle: String,
                team: UUID,
                isUpgradingMLSClient: Bool,
                authenticate: OAuthBlock) async throws

}

/// This class provides an interface to issue an E2EI certificate.
public final class EnrollE2eICertificateUseCase: EnrollE2eICertificateUseCaseInterface {

    var e2eiRepository: E2eIRepositoryInterface

    public init(e2eiRepository: E2eIRepositoryInterface) {
        self.e2eiRepository = e2eiRepository
    }

    public func invoke(e2eiClientId: E2eIClientID,
                       userName: String,
                       userHandle: String,
                       team: UUID,
                       isUpgradingMLSClient: Bool,
                       authenticate: OAuthBlock) async throws {
        try await e2eiRepository.fetchTrustAnchor()

        let enrollment = try await e2eiRepository.createEnrollment(e2eiClientId: e2eiClientId,
                                                                   userName: userName,
                                                                   handle: userHandle,
                                                                   team: team,
                                                                   isUpgradingClient: isUpgradingMLSClient)

        let acmeNonce = try await enrollment.getACMENonce()
        let newAccountNonce = try await enrollment.createNewAccount(prevNonce: acmeNonce)
        let newOrder = try await enrollment.createNewOrder(prevNonce: newAccountNonce)
        let authorizations = try await enrollment.getAuthorizations(
            prevNonce: newOrder.nonce,
            authorizationsEndpoints: newOrder.acmeOrder.authorizations)
        let oidcAuthorization = authorizations.oidcAuthorization
        let dPopAuthorization = authorizations.dpopAuthorization

        let keyauth = oidcAuthorization.keyauth ?? ""
        let acmeAudience = oidcAuthorization.challenge.url

        guard let identityProvider = URL(string: oidcAuthorization.challenge.target) else {
            throw EnrollE2EICertificateUseCaseFailure.missingIdentityProvider
        }

        guard let clientId = extractClientId(from: oidcAuthorization.challenge.target) else {
            throw EnrollE2EICertificateUseCaseFailure.missingClientId
        }

        let (idToken, refreshToken) = try await authenticate(identityProvider, clientId, keyauth, acmeAudience)
        let wireNonce = try await enrollment.getWireNonce(clientId: e2eiClientId.clientID)
        let dpopToken = try await enrollment.getDPoPToken(wireNonce)
        let wireAccessToken = try await enrollment.getWireAccessToken(clientId: e2eiClientId.clientID,
                                                                      dpopToken: dpopToken)

        let refreshTokenFromCC = try? await enrollment.getOAuthRefreshToken()

        let dpopChallengeResponse = try await enrollment.validateDPoPChallenge(accessToken: wireAccessToken.token,
                                                                               prevNonce: authorizations.nonce,
                                                                               acmeChallenge: dPopAuthorization.challenge)

        let oidcChallengeResponse = try await enrollment.validateOIDCChallenge(idToken: idToken,
                                                                               refreshToken: refreshTokenFromCC ?? refreshToken,
                                                                               prevNonce: dpopChallengeResponse.nonce,
                                                                               acmeChallenge: oidcAuthorization.challenge)

        let orderResponse = try await enrollment.checkOrderRequest(location: newOrder.location, prevNonce: oidcChallengeResponse.nonce)
        let finalizeResponse = try await enrollment.finalize(location: orderResponse.location, prevNonce: orderResponse.acmeResponse.nonce)
        let certificateRequest = try await enrollment.certificateRequest(location: finalizeResponse.location,
                                                                         prevNonce: finalizeResponse.acmeResponse.nonce)

        do {
            guard let certificateChain = String(bytes: certificateRequest.response.bytes, encoding: .utf8) else {
                throw EnrollE2EICertificateUseCaseFailure.failedToDecodeCertificate
            }
            if isUpgradingMLSClient {
                try await enrollment.rotateKeysAndMigrateConversations(certificateChain: certificateChain)
            } else {
                try await enrollment.createMLSClient(certificateChain: certificateChain)
            }
        } catch is DecodingError {
            throw EnrollE2EICertificateUseCaseFailure.failedToDecodeCertificate
        }

    }

    private func extractClientId(from path: String) -> String? {
        guard let urlComponents = URLComponents(string: path),
              let clientId = urlComponents.queryItems?.first(where: { $0.name == "client_id" })?.value else {
            return nil
        }
        return clientId
    }

}

enum EnrollE2EICertificateUseCaseFailure: Error {

    case failedToSetupEnrollment
    case missingIdentityProvider
    case missingClientId
    case failedToDecodeCertificate

}
