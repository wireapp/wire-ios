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

import Combine
import CoreData
import Foundation
import WireCoreCrypto
import WireLogging
import WireTransport

public protocol E2EIRepositoryInterface {

    func fetchTrustAnchor() async throws

    func fetchFederationCertificates() async throws

}

public final class E2EIRepository: E2EIRepositoryInterface {

    // MARK: - Types

    enum Error: Swift.Error {
        case failedToGetSelfUserInfo
        case missingSelfClientID
        case missingE2eIAPI
    }

    // MARK: - Properties

    private let acmeApi: AcmeAPIInterface
    private let coreCryptoProvider: CoreCryptoProviderProtocol
    private let logger: WireLogger = .e2ei

    // MARK: - Life cycle

    public init(
        acmeApi: AcmeAPIInterface,
        coreCryptoProvider: CoreCryptoProviderProtocol,
    ) {
        self.acmeApi = acmeApi
        self.coreCryptoProvider = coreCryptoProvider
    }

    // MARK: - Interface

    public func fetchTrustAnchor() async throws {
        guard let pkiEnvironment = await coreCryptoProvider.pkiEnvironment() else {
            throw Error.missingE2eIAPI
        }

        let trustAnchor = try await acmeApi.getTrustAnchor()
        try await pkiEnvironment.addTrustAnchor(certPem: trustAnchor)
    }

    public func fetchFederationCertificates() async throws {
        guard let pkiEnvironment = await coreCryptoProvider.pkiEnvironment() else {
            throw Error.missingE2eIAPI
        }

        for intermediate in try await acmeApi.getFederationCertificates() {
            try await pkiEnvironment.addIntermediateCert(certPem: intermediate)
        }
    }

}
