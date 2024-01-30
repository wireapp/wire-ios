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
import WireCoreCrypto

public protocol E2eIRepositoryInterface {

    func fetchTrustAnchor() async throws

    func fetchFederationCertificate() async throws

    func createEnrollment(context: NSManagedObjectContext) async throws -> E2eIEnrollmentInterface
}

public final class E2eIRepository: E2eIRepositoryInterface {

    // MARK: - Types

    enum Error: Swift.Error {
        case failedToGetSelfUserInfo
    }

    // MARK: - Properties

    private let acmeApi: AcmeAPIInterface
    private let apiProvider: APIProviderInterface
    private let e2eiSetupService: E2eISetupServiceInterface
    private let keyRotator: E2eIKeyPackageRotating
    private let coreCryptoProvider: CoreCryptoProviderProtocol

    // MARK: - Life cycle

    public init(
        acmeApi: AcmeAPIInterface,
        apiProvider: APIProviderInterface,
        e2eiSetupService: E2eISetupServiceInterface,
        keyRotator: E2eIKeyPackageRotating,
        coreCryptoProvider: CoreCryptoProviderProtocol
    ) {
        self.acmeApi = acmeApi
        self.apiProvider = apiProvider
        self.e2eiSetupService = e2eiSetupService
        self.keyRotator = keyRotator
        self.coreCryptoProvider = coreCryptoProvider
    }

    // MARK: - Interface

    public func fetchTrustAnchor() async throws {
        let trustAnchor = try await acmeApi.getTrustAnchor()
        try await e2eiSetupService.registerTrustAnchor(trustAnchor)
    }

    public func fetchFederationCertificate() async throws {
        let federationCertificate = try await acmeApi.getFederationCertificate()
        try await e2eiSetupService.registerFederationCertificate(federationCertificate)
    }

    public func createEnrollment(context: NSManagedObjectContext) async throws -> E2eIEnrollmentInterface {
        let (userName, userHandle, teamId) = try await context.perform {
            let selfUser = ZMUser.selfUser(in: context)
            guard let userName = selfUser.name,
                  let userHandle = selfUser.handle,
                  let teamId = selfUser.team?.remoteIdentifier else {
                throw Error.failedToGetSelfUserInfo
            }
            return (userName, userHandle, teamId)
        }

        let e2eIdentity = try await e2eiSetupService.setupEnrollment(
            userName: userName,
            handle: userHandle,
            teamId: teamId
        )

        let e2eiService = E2eIService(e2eIdentity: e2eIdentity, coreCryptoProvider: coreCryptoProvider)
        let acmeDirectory = try await loadACMEDirectory(e2eiService: e2eiService)

        return E2eIEnrollment(
            acmeApi: acmeApi,
            apiProvider: apiProvider,
            e2eiService: e2eiService,
            acmeDirectory: acmeDirectory,
            keyRotator: keyRotator
        )
    }

    // MARK: - Helpers

    private func loadACMEDirectory(e2eiService: E2eIService) async throws -> AcmeDirectory {
        let acmeDirectoryData = try await acmeApi.getACMEDirectory()
        return try await e2eiService.getDirectoryResponse(directoryData: acmeDirectoryData)
    }

}
