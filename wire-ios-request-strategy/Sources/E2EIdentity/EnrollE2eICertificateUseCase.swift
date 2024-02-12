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

    func invoke(authenticate: OAuthBlock) async throws

}

/// This class provides an interface to issue an E2EI certificate.
public final class EnrollE2eICertificateUseCase: EnrollE2eICertificateUseCaseInterface {

    // MARK: - Types

    enum Failure: Error {
        case missingIdentityProvider
        case missingClientId
        case failedToDecodeCertificate
        case failedToEnrollCertificate(_ underlyingError: Error)
    }

    // MARK: - Properties

    private let logger = WireLogger.e2ei
    private let e2eiRepository: E2eIRepositoryInterface
    private let context: NSManagedObjectContext

    // MARK: - Life cycle

    public init(e2eiRepository: E2eIRepositoryInterface,
                context: NSManagedObjectContext) {
        self.e2eiRepository = e2eiRepository
        self.context = context
    }

    public func invoke(authenticate: OAuthBlock) async throws {
        do {
            try await e2eiRepository.fetchTrustAnchor()
        } catch {
            logger.warn("failed to register trust anchor: \(error.localizedDescription)")
        }

        let enrollment = try await e2eiRepository.createEnrollment(context: context)

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
            throw Failure.missingIdentityProvider
        }

        guard let clientId = extractClientId(from: oidcAuthorization.challenge.target) else {
            throw Failure.missingClientId
        }

        let selfClientId = await context.perform {
            ZMUser.selfUser(in: self.context).selfClient()?.remoteIdentifier
        }
        let (idToken, refreshToken) = try await authenticate(identityProvider, clientId, keyauth, acmeAudience)
        let wireNonce = try await enrollment.getWireNonce(clientId: selfClientId ?? "")
        let dpopToken = try await enrollment.getDPoPToken(wireNonce)
        let wireAccessToken = try await enrollment.getWireAccessToken(clientId: selfClientId ?? "",
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
                throw Failure.failedToDecodeCertificate
            }
            try await enrollment.rotateKeysAndMigrateConversations(certificateChain: certificateChain)
        } catch {
            throw Failure.failedToEnrollCertificate(error)
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
