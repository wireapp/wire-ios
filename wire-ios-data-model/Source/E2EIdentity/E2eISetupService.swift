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

public protocol E2eISetupServiceInterface {

    func registerTrustAnchor(_ trustAnchor: String) async throws

    func registerFederationCertificate(_ certificate: String) async throws

    func setupEnrollment(
        clientID: E2eIClientID,
        userName: String,
        handle: String,
        teamId: UUID,
        isUpgradingClient: Bool
    ) async throws -> E2eiEnrollment

}

/// This class setups e2eIdentity object from CoreCrypto.
public final class E2eISetupService: E2eISetupServiceInterface {

    // MARK: - Properties

    private let coreCryptoProvider: CoreCryptoProviderProtocol
    private var coreCrypto: SafeCoreCryptoProtocol {
        get async throws {
            try await coreCryptoProvider.coreCrypto()
        }
    }

    // MARK: - Life cycle

    public init(coreCryptoProvider: CoreCryptoProviderProtocol) {
        self.coreCryptoProvider = coreCryptoProvider
    }

    // MARK: - Public interface

    public func registerTrustAnchor(_ trustAnchor: String) async throws {
        try await coreCryptoProvider.coreCrypto().perform { coreCrypto in
            try await coreCrypto.e2eiRegisterAcmeCa(trustAnchorPem: trustAnchor)
        }
    }

    public func registerFederationCertificate(_ certificate: String) async throws {
        try await coreCryptoProvider.coreCrypto().perform { coreCrypto in
            _ = try await coreCrypto.e2eiRegisterIntermediateCa(certPem: certificate)
        }
    }

    public func setupEnrollment(
        clientID: E2eIClientID,
        userName: String,
        handle: String,
        teamId: UUID,
        isUpgradingClient: Bool
    ) async throws -> E2eiEnrollment {
        do {
            return try await setupNewActivationOrRotate(
                clientID: clientID,
                userName: userName,
                handle: handle,
                teamId: teamId,
                isUpgradingClient: isUpgradingClient
            )
        } catch {
            throw Failure.failedToSetupE2eIClient(error)
        }
    }

    private func setupNewActivationOrRotate(
        clientID: E2eIClientID,
        userName: String,
        handle: String,
        teamId: UUID,
        isUpgradingClient: Bool
    ) async throws -> E2eiEnrollment {
            let ciphersuite = CiphersuiteName.default.rawValue
            let expirySec = UInt32(TimeInterval.oneDay * 90)

            return try await coreCrypto.perform {
                if isUpgradingClient {
                    let e2eiIsEnabled = try await $0.e2eiIsEnabled(ciphersuite: ciphersuite)
                    if e2eiIsEnabled {
                        return try await $0.e2eiNewRotateEnrollment(displayName: userName,
                                                                    handle: handle,
                                                                    team: teamId.uuidString.lowercased(),
                                                                    expirySec: expirySec,
                                                                    ciphersuite: ciphersuite)
                    } else {
                        return try await $0.e2eiNewActivationEnrollment(displayName: userName,
                                                                        handle: handle,
                                                                        team: teamId.uuidString.lowercased(),
                                                                        expirySec: expirySec,
                                                                        ciphersuite: ciphersuite)
                    }
                } else {
                    return try await $0.e2eiNewEnrollment(
                        clientId: clientID.rawValue,
                        displayName: userName,
                        handle: handle,
                        team: teamId.uuidString.lowercased(),
                        expirySec: expirySec,
                        ciphersuite: ciphersuite)
                }
            }
        }

    enum Failure: Error {
        case failedToSetupE2eIClient(_ underlyingError: Error?)
    }

}
