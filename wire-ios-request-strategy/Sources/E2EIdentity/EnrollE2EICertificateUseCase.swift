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

import Foundation

// MARK: - OAuthParameters

public struct OAuthParameters {
    public let identityProvider: URL
    public let clientID: String
    public let keyauth: String
    public let acmeAudience: String
}

// MARK: - OAuthResponse

public struct OAuthResponse {
    // MARK: Lifecycle

    public init(
        idToken: String,
        refreshToken: String?
    ) {
        self.idToken = idToken
        self.refreshToken = refreshToken
    }

    // MARK: Internal

    let idToken: String
    let refreshToken: String?
}

public typealias OAuthBlock = (OAuthParameters) async throws -> OAuthResponse

// MARK: - EnrollE2EICertificateUseCaseProtocol

// sourcery: AutoMockable
public protocol EnrollE2EICertificateUseCaseProtocol {
    func invoke(authenticate: @escaping OAuthBlock) async throws -> String
}

// MARK: - EnrollE2EICertificateUseCase

/// This class provides an interface to issue an E2EI certificate.
public final class EnrollE2EICertificateUseCase: EnrollE2EICertificateUseCaseProtocol {
    // MARK: Lifecycle

    public init(
        e2eiRepository: E2EIRepositoryInterface,
        context: NSManagedObjectContext
    ) {
        self.e2eiRepository = e2eiRepository
        self.context = context
    }

    // MARK: Public

    /// Invokes enrollment flow
    /// - Parameter authenticate: Block that performs OAUTH authentication
    /// - Returns: Chain of certificates for the clients
    /// - Description: **Visit the link below to understand the entire flow**  https://wearezeta.atlassian.net/wiki/spaces/ENGINEERIN/pages/800820113/Use+case+End-to-end+identity+enrollment#Detailed-enrolment-flow
    public func invoke(authenticate: @escaping OAuthBlock) async throws -> String {
        try await invoke(authenticate: authenticate, expirySec: nil)
    }

    public func invoke(authenticate: @escaping OAuthBlock, expirySec: UInt32?) async throws -> String {
        do {
            try await e2eiRepository.fetchTrustAnchor()
        } catch {
            logger.warn("failed to register trust anchor: \(error.localizedDescription)")
            throw error
        }

        do {
            try await e2eiRepository.fetchFederationCertificates()
        } catch {
            logger.warn("failed to register intermediate certificates: \(String(describing: error))")
            throw error
        }

        let enrollment = try await e2eiRepository.createEnrollment(
            context: context,
            expirySec: expirySec
        )

        let acmeNonce = try await enrollment.getACMENonce()
        let newAccountNonce = try await enrollment.createNewAccount(prevNonce: acmeNonce)
        let newOrder = try await enrollment.createNewOrder(prevNonce: newAccountNonce)

        let authorizations = try await enrollment.getAuthorizations(
            prevNonce: newOrder.nonce,
            authorizationsEndpoints: newOrder.acmeOrder.authorizations
        )
        let oidcAuthorization = authorizations.oidcAuthorization
        let dPopAuthorization = authorizations.dpopAuthorization

        let keyauth = oidcAuthorization.keyauth ?? ""
        let acmeAudience = oidcAuthorization.challenge.url

        guard let idP = URL(string: oidcAuthorization.challenge.target) else {
            throw Failure.missingIdentityProvider
        }

        guard let clientId = extractClientId(from: oidcAuthorization.challenge.target) else {
            throw Failure.missingClientId
        }

        let selfClientId = await context.perform {
            ZMUser.selfUser(in: self.context).selfClient()?.remoteIdentifier
        }

        guard let selfClientId else {
            throw Failure.missingSelfClientID
        }

        let isUpgradingMLSClient = await context.perform {
            ZMUser.selfUser(in: self.context).selfClient()?.hasRegisteredMLSClient ?? false
        }

        let parameters = OAuthParameters(
            identityProvider: idP,
            clientID: clientId,
            keyauth: keyauth,
            acmeAudience: acmeAudience
        )
        let oAuthResponse = try await authenticate(parameters)

        let wireNonce = try await enrollment.getWireNonce(clientId: selfClientId)
        let dpopToken = try await enrollment.getDPoPToken(wireNonce)
        let wireAccessToken = try await enrollment.getWireAccessToken(
            clientId: selfClientId,
            dpopToken: dpopToken
        )

        let dpopChallengeResponse = try await enrollment.validateDPoPChallenge(
            accessToken: wireAccessToken.token,
            prevNonce: authorizations.nonce,
            acmeChallenge: dPopAuthorization.challenge
        )

        let oidcChallengeResponse = try await enrollment.validateOIDCChallenge(
            idToken: oAuthResponse.idToken,
            refreshToken: oAuthResponse.refreshToken ?? " ",
            prevNonce: dpopChallengeResponse.nonce,
            acmeChallenge: oidcAuthorization.challenge
        )

        let orderResponse = try await enrollment.checkOrderRequest(
            location: newOrder.location,
            prevNonce: oidcChallengeResponse.nonce
        )

        let finalizeResponse = try await enrollment.finalize(
            location: orderResponse.location,
            prevNonce: orderResponse.acmeResponse.nonce
        )

        let certificateRequest = try await enrollment.certificateRequest(
            location: finalizeResponse.location,
            prevNonce: finalizeResponse.acmeResponse.nonce
        )

        guard let certificateChain = String(bytes: certificateRequest.response.bytes, encoding: .utf8) else {
            throw Failure.failedToDecodeCertificate
        }

        do {
            try await rollingOutCertificate(
                isUpgradingMLSClient: isUpgradingMLSClient,
                enrollment: enrollment,
                certificateChain: certificateChain
            )
            notifyE2EICertificateChange()

            return certificateChain
        } catch {
            throw Failure.failedToEnrollCertificate(error)
        }
    }

    // MARK: Internal

    // MARK: - Types

    enum Failure: Error {
        case missingIdentityProvider
        case missingClientId
        case missingSelfClientID
        case failedToDecodeCertificate
        case failedToEnrollCertificate(_ underlyingError: Error)
    }

    // MARK: Private

    // MARK: - Properties

    private let logger = WireLogger.e2ei
    private let e2eiRepository: E2EIRepositoryInterface
    private let context: NSManagedObjectContext

    private func rollingOutCertificate(
        isUpgradingMLSClient: Bool,
        enrollment: E2EIEnrollmentInterface,
        certificateChain: String
    ) async throws {
        if isUpgradingMLSClient {
            try await enrollment.rotateKeysAndMigrateConversations(certificateChain: certificateChain)
        } else {
            try await enrollment.createMLSClient(certificateChain: certificateChain)
        }
    }

    private func extractClientId(from path: String) -> String? {
        guard let urlComponents = URLComponents(string: path),
              let clientId = urlComponents.queryItems?.first(where: { $0.name == "client_id" })?.value else {
            return nil
        }
        return clientId
    }

    private func notifyE2EICertificateChange() {
        NotificationCenter.default.post(name: .e2eiCertificateChanged, object: self)
    }
}
