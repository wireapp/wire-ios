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

import Combine
import Foundation
import WireCoreCrypto

// MARK: - E2EIRepositoryInterface

public protocol E2EIRepositoryInterface {
    func fetchTrustAnchor() async throws

    func fetchFederationCertificates() async throws

    func createEnrollment(
        context: NSManagedObjectContext,
        expirySec: UInt32?
    ) async throws -> E2EIEnrollmentInterface
}

// MARK: - E2EIRepository

public final class E2EIRepository: E2EIRepositoryInterface {
    // MARK: - Types

    enum Error: Swift.Error {
        case failedToGetSelfUserInfo
    }

    // MARK: - Properties

    private let acmeApi: AcmeAPIInterface
    private let apiProvider: APIProviderInterface
    private let e2eiSetupService: E2EISetupServiceInterface
    private let keyRotator: E2EIKeyPackageRotating
    private let coreCryptoProvider: CoreCryptoProviderProtocol
    private let logger: WireLogger = .e2ei
    private let onNewCRLsDistributionPointsSubject: PassthroughSubject<CRLsDistributionPoints, Never>

    // MARK: - Life cycle

    public init(
        acmeApi: AcmeAPIInterface,
        apiProvider: APIProviderInterface,
        e2eiSetupService: E2EISetupServiceInterface,
        keyRotator: E2EIKeyPackageRotating,
        coreCryptoProvider: CoreCryptoProviderProtocol,
        onNewCRLsDistributionPointsSubject: PassthroughSubject<CRLsDistributionPoints, Never>
    ) {
        self.acmeApi = acmeApi
        self.apiProvider = apiProvider
        self.e2eiSetupService = e2eiSetupService
        self.keyRotator = keyRotator
        self.coreCryptoProvider = coreCryptoProvider
        self.onNewCRLsDistributionPointsSubject = onNewCRLsDistributionPointsSubject
    }

    // MARK: - Interface

    public func fetchTrustAnchor() async throws {
        guard try await !e2eiSetupService.isTrustAnchorRegistered() else {
            logger.info("Trust anchor is already registered, skipping.")
            return
        }
        let trustAnchor = try await acmeApi.getTrustAnchor()
        try await e2eiSetupService.registerTrustAnchor(trustAnchor)
    }

    public func fetchFederationCertificates() async throws {
        let federationCertificates = try await acmeApi.getFederationCertificates()
        for certificate in federationCertificates {
            do {
                try await e2eiSetupService.registerFederationCertificate(certificate)
            } catch {
                logger
                    .warn(
                        "failed to register certificate (error: \(String(describing: error)), certificate: \(certificate))"
                    )
            }
        }
    }

    public func createEnrollment(
        context: NSManagedObjectContext,
        expirySec: UInt32?
    ) async throws -> E2EIEnrollmentInterface {
        let (userName, userHandle, teamId, clientID, isUpgradingClient) = try await context.perform {
            let selfUser = ZMUser.selfUser(in: context)
            let isUpgradingClient = selfUser.selfClient()?.hasRegisteredMLSClient ?? false
            guard let userName = selfUser.name,
                  let userHandle = selfUser.handle,
                  let teamId = selfUser.teamIdentifier,
                  let clientID = E2EIClientID(user: selfUser) else {
                throw Error.failedToGetSelfUserInfo
            }
            return (userName, userHandle, teamId, clientID, isUpgradingClient)
        }

        let e2eIdentity = try await e2eiSetupService.setupEnrollment(
            clientID: clientID,
            userName: userName,
            handle: userHandle,
            teamId: teamId,
            isUpgradingClient: isUpgradingClient,
            expirySec: expirySec
        )

        let e2eiService = E2EIService(
            e2eIdentity: e2eIdentity,
            coreCryptoProvider: coreCryptoProvider,
            onNewCRLsDistributionPointsSubject: onNewCRLsDistributionPointsSubject
        )

        let acmeDirectory = try await loadACMEDirectory(e2eiService: e2eiService)

        return E2EIEnrollment(
            acmeApi: acmeApi,
            apiProvider: apiProvider,
            e2eiService: e2eiService,
            acmeDirectory: acmeDirectory,
            keyRotator: keyRotator
        )
    }

    // MARK: - Helpers

    private func loadACMEDirectory(e2eiService: E2EIService) async throws -> AcmeDirectory {
        let acmeDirectoryData = try await acmeApi.getACMEDirectory()
        return try await e2eiService.getDirectoryResponse(directoryData: acmeDirectoryData)
    }
}
