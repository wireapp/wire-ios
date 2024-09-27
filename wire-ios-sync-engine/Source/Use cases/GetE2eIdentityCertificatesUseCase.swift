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
import WireCoreCrypto
import WireDataModel

// MARK: - GetE2eIdentityCertificatesUseCaseProtocol

// sourcery: AutoMockable
public protocol GetE2eIdentityCertificatesUseCaseProtocol {
    func invoke(
        mlsGroupId: MLSGroupID,
        clientIds: [MLSClientID]
    ) async throws -> [E2eIdentityCertificate]
}

// MARK: - GetE2eIdentityCertificatesUseCase

public final class GetE2eIdentityCertificatesUseCase: GetE2eIdentityCertificatesUseCaseProtocol {
    private let coreCryptoProvider: CoreCryptoProviderProtocol
    private let syncContext: NSManagedObjectContext

    public init(
        coreCryptoProvider: CoreCryptoProviderProtocol,
        syncContext: NSManagedObjectContext
    ) {
        self.coreCryptoProvider = coreCryptoProvider
        self.syncContext = syncContext
    }

    public func invoke(
        mlsGroupId: MLSGroupID,
        clientIds: [MLSClientID]
    ) async throws -> [E2eIdentityCertificate] {
        let coreCrypto = try await coreCryptoProvider.coreCrypto()
        let clientIds = clientIds.compactMap { $0.rawValue.data(using: .utf8) }
        let identities = try await getWireIdentity(
            coreCrypto: coreCrypto,
            conversationId: mlsGroupId.data,
            clientIDs: clientIds
        )
        let identitiesAndStatus = await validateUserHandleAndName(for: identities)

        return identitiesAndStatus.map { identity, status in
            if let x509Identity = identity.x509Identity {
                E2eIdentityCertificate(
                    clientId: identity.clientId,
                    certificateDetails: x509Identity.certificate,
                    mlsThumbprint: identity.thumbprint,
                    notValidBefore: Date(timeIntervalSince1970: Double(x509Identity.notBefore)),
                    expiryDate: Date(timeIntervalSince1970: Double(x509Identity.notAfter)),
                    certificateStatus: status,
                    serialNumber: x509Identity.serialNumber
                )
            } else {
                E2eIdentityCertificate(
                    clientId: identity.clientId,
                    certificateDetails: "",
                    mlsThumbprint: identity.thumbprint,
                    notValidBefore: .now,
                    expiryDate: .now,
                    certificateStatus: .notActivated,
                    serialNumber: ""
                )
            }
        }
    }

    // Core Crypto can't validate the user name and handle because it doesn't know the actual
    // values so we perform additional validation.

    private func validateUserHandleAndName(for identities: [WireIdentity]) async -> [(
        WireIdentity,
        E2EIdentityCertificateStatus
    )] {
        var validatedIdentities = [(WireIdentity, E2EIdentityCertificateStatus)]()
        for identity in identities {
            // The identity is valid according to CoreCrypto.
            guard identity.status == .valid else {
                validatedIdentities.append((identity, identity.status.e2eIdentityStatus))
                continue
            }

            guard let mlsClientID = MLSClientID(rawValue: identity.clientId) else {
                validatedIdentities.append((identity, .invalid))
                continue
            }

            let (name, handle, domain) = await syncContext.perform {
                let client = UserClient.fetchExistingUserClient(with: mlsClientID.clientID, in: self.syncContext)
                return (client?.user?.name, client?.user?.handle, client?.user?.domain)
            }

            guard let name, let handle, let domain else {
                validatedIdentities.append((identity, .invalid))
                continue
            }

            let hasValidDisplayName = identity.x509Identity?.displayName == name
            let hasValidHandle = identity.x509Identity?.handle.contains("\(handle)@\(domain)") ?? false
            let isValid = hasValidDisplayName && hasValidHandle
            validatedIdentities.append((identity, isValid ? .valid : .invalid))
        }
        return validatedIdentities
    }

    @MainActor
    private func getWireIdentity(
        coreCrypto: SafeCoreCryptoProtocol,
        conversationId: Data,
        clientIDs: [Data]
    ) async throws -> [WireIdentity] {
        try await coreCrypto.perform {
            try await $0.getDeviceIdentities(
                conversationId: conversationId,
                deviceIds: clientIDs
            )
        }
    }
}

extension DeviceStatus {
    fileprivate var e2eIdentityStatus: E2EIdentityCertificateStatus {
        switch self {
        case .valid:
            return .valid
        case .expired:
            return .expired
        case .revoked:
            return .revoked
        @unknown default:
            preconditionFailure("Should have a valid status")
        }
    }
}
