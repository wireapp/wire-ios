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

import CoreData
import Foundation
import WireCoreCrypto
import WireLogging

public struct OAuthParameters {

    public let identityProvider: URL
    public let clientID: String
    public let keyauth: String
    public let acmeAudience: String
    public let acquisitionSnapshot: Data

}

public struct OAuthResponse {

    let idToken: String
    let refreshToken: String?

    public init(
        idToken: String,
        refreshToken: String?
    ) {
        self.idToken = idToken
        self.refreshToken = refreshToken
    }

}

public typealias OAuthBlock = (OAuthParameters) async throws -> OAuthResponse

// sourcery: AutoMockable
public protocol EnrollE2EICertificateUseCaseProtocol {

    func invoke(authenticate: @escaping OAuthBlock) async throws -> String

}

/// This class provides an interface to issue an E2EI certificate.
public final class EnrollE2EICertificateUseCase: EnrollE2EICertificateUseCaseProtocol {

    // MARK: - Types

    enum Failure: Error {
        case missingSelfClientID
        case missingSelfUserInfo
        case missingAcmeDiscoveryUrl
        case missingE2eIAPI
        case missingPKIEnvironment
        case failedToEnrollCertificate(_ underlyingError: Error)
    }

    // MARK: - Properties

    private let logger = WireLogger.e2ei
    private let e2eiRepository: E2EIRepositoryInterface
    private let crlURLBuilder: CRLURLBuilder
    private let localDomain: String?
    private let apiVersion: APIVersion?
    private let apiProvider: APIProviderInterface
    private let featureRepository: LegacyFeatureRepositoryInterface
    private let keyRotator: E2EIKeyPackageRotating
    private let coreCryptoProvider: CoreCryptoProviderProtocol
    private let context: NSManagedObjectContext

    // MARK: - Life cycle

    public init(
        e2eiRepository: E2EIRepositoryInterface,
        apiVersion: APIVersion?,
        apiProvider: APIProviderInterface,
        crlURLBuilder: CRLURLBuilder,
        featureRepository: LegacyFeatureRepositoryInterface,
        keyRotator: E2EIKeyPackageRotating,
        coreCryptoProvider: CoreCryptoProviderProtocol,
        localDomain: String?,
        context: NSManagedObjectContext
    ) {
        self.e2eiRepository = e2eiRepository
        self.apiVersion = apiVersion
        self.crlURLBuilder = crlURLBuilder
        self.localDomain = localDomain
        self.apiProvider = apiProvider
        self.featureRepository = featureRepository
        self.keyRotator = keyRotator
        self.coreCryptoProvider = coreCryptoProvider
        self.context = context
    }

    /// Invokes enrollment flow
    /// - Parameter authenticate: Block that performs OAUTH authentication
    /// - Returns: Chain of certificates for the clients
    /// - Description: **Visit the link below to understand the entire flow**  https://wearezeta.atlassian.net/wiki/spaces/ENGINEERIN/pages/800820113/Use+case+End-to-end+identity+enrollment#Detailed-enrolment-flow
    public func invoke(authenticate: @escaping OAuthBlock) async throws -> String {
        try await invoke(authenticate: authenticate, expirySec: nil)
    }

    public func invoke(authenticate: @escaping OAuthBlock, expirySec: UInt32?) async throws -> String {
        let isUpgradingMLSClient = await context.perform {
            ZMUser.selfUser(in: self.context).selfClient()?.hasRegisteredMLSClient ?? false
        }

        do {
            let acquisition = try await createX509CredentialAcquisition(
                context: context,
                expirySec: expirySec,
                authenticate: authenticate
            )

            let credential = try await acquisition.finalize()

            if isUpgradingMLSClient {
                try await rotateKeysAndMigrateConversations(credential: credential)
            } else {
                try await createMLSClient(context: context, credential: credential)
            }

            notifyE2EICertificateChange()

            return credential.exportPem()
        } catch let error as E2EIRepository.Error {
            switch error {
            case .missingSelfClientID:
                throw Failure.missingSelfClientID
            case .failedToGetSelfUserInfo, .missingE2eIAPI:
                throw Failure.failedToEnrollCertificate(error)
            }
        } catch {
            logger.warn("failed to enroll certificate: \(error.localizedDescription)")
            throw Failure.failedToEnrollCertificate(error)
        }
    }

    private func createX509CredentialAcquisition(
        context: NSManagedObjectContext,
        expirySec: UInt32?,
        authenticate: @escaping OAuthBlock
    ) async throws -> X509CredentialAcquisition {
        let localDomain = localDomain
        let (userName, userHandle, userId, teamId, selfClientId, domain) = try await context.perform {
            let selfUser = ZMUser.selfUser(in: context)

            guard let userName = selfUser.name,
                  let userHandle = selfUser.handle,
                  let teamId = selfUser.teamIdentifier,
                  let domain = localDomain ?? selfUser.domain
            else {
                throw Failure.missingSelfUserInfo
            }

            guard let selfClientId = selfUser.selfClient()?.remoteIdentifier else {
                throw Failure.missingSelfClientID
            }

            let userId = selfUser.remoteIdentifier.transportString()

            return (userName, userHandle, userId, teamId, selfClientId, domain)
        }

        let clientId: WireCoreCrypto.ClientId = ClientId(
            userId: try Uuid(uuid: userId),
            deviceId: try DeviceId.fromHexString(hexString: selfClientId),
            domain: domain
        )

        guard let acmeDiscoveryUrl = await context.perform({ self.featureRepository.fetchE2EI().config.acmeDiscoveryUrl
        }) else {
            throw Failure.missingAcmeDiscoveryUrl
        }

        let ciphersuite = await featureRepository.fetchMLS().config.defaultCipherSuite.coreCryptoCipherSuite

        let existingCredential = try await coreCryptoProvider.coreCrypto().coreCrypto.findCredentials(
            clientId: nil,
            publicKey: nil,
            cipherSuite: ciphersuite,
            credentialType: nil,
            earliestValidity: nil
        ).first

        guard let apiVersion,
              let e2eiApi = apiProvider.e2eIAPI(apiVersion: apiVersion) else {
            throw Failure.missingE2eIAPI
        }

        guard let pkiEnvironment = await coreCryptoProvider.pkiEnvironment() else {
            throw Failure.missingPKIEnvironment
        }

        let hooks = PKIEnvironmentTransport(
            selfClientId: selfClientId,
            e2eiApi: e2eiApi,
            crlURLbuilder: crlURLBuilder,
            oauthAuthenticate: authenticate
        )

        coreCryptoProvider.registerPkiEnvironmentHooks(hooks)

        try await e2eiRepository.fetchTrustAnchor()
        try await e2eiRepository.fetchFederationCertificates()

        let config = X509CredentialAcquisitionConfiguration(
            acmeDirectoryUrl: acmeDiscoveryUrl,
            cipherSuite: ciphersuite,
            displayName: userName,
            clientId: clientId,
            handle: userHandle,
            domain: domain,
            team: teamId.transportString(),
            validityPeriodSecs: UInt64(expirySec ?? UInt32(TimeInterval.oneDay * 90))
        )

        if let existingCredential {
            return try await x509CredentialAcquisitionNewFromCredentialRef(
                pkiEnvironment: pkiEnvironment,
                config: config,
                credentialRef: existingCredential,
                coreCryptoDatabase: nil
            )
        } else {
            return try X509CredentialAcquisition(pkiEnvironment: pkiEnvironment, config: config)
        }
    }

    private func rotateKeysAndMigrateConversations(credential: Credential) async throws {
        try await keyRotator.rotateKeysAndMigrateConversations(credential: credential)
    }

    private func createMLSClient(context: NSManagedObjectContext, credential: Credential) async throws {
        let localDomain = localDomain
        let mlsClientID = try await context.perform {
            guard let selfClient = ZMUser.selfUser(in: context).selfClient(),
                  let mlsClientID = MLSClientID(userClient: selfClient, localDomain: localDomain) else {
                throw Failure.missingSelfClientID
            }
            return mlsClientID
        }

        _ = try await coreCryptoProvider.initialiseMLSWithEndToEndIdentity(
            mlsClientID: mlsClientID,
            credential: credential
        )
    }

    private func notifyE2EICertificateChange() {
        NotificationCenter.default.post(name: .e2eiCertificateChanged, object: self)
    }

}
