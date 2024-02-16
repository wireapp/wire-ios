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
import WireDataModel
import WireCoreCrypto
import ASN1Decoder

// sourcery: AutoMockable
public protocol GetE2eIdentityCertificatesUseCaseProtocol {
    func invoke(mlsGroupId: MLSGroupID,
                clientIds: [MLSClientID]) async throws -> [E2eIdentityCertificate]
}

final public class GetE2eIdentityCertificatesUseCase: GetE2eIdentityCertificatesUseCaseProtocol {
    private let coreCryptoProvider: CoreCryptoProviderProtocol

    public init(coreCryptoProvider: CoreCryptoProviderProtocol) {
        self.coreCryptoProvider = coreCryptoProvider
    }

    public func invoke(mlsGroupId: MLSGroupID,
                       clientIds: [MLSClientID]) async throws -> [E2eIdentityCertificate] {

        let coreCrypto = try await coreCryptoProvider.coreCrypto(requireMLS: true)
        let clientIds = clientIds.compactMap({ $0.rawValue.data(using: .utf8) })
        let wireIdentities = try await getWireIdentity(coreCrypto: coreCrypto,
                                                       conversationId: mlsGroupId.data,
                                                       clientIDs: clientIds)
        return try wireIdentities.compactMap({ try $0.toE2eIdenityCertificate() })
    }

    @MainActor
    private func getWireIdentity(coreCrypto: SafeCoreCryptoProtocol,
                                 conversationId: Data, clientIDs: [Data]) async throws -> [WireIdentity] {
        return try await coreCrypto.perform {
            return try await $0.getDeviceIdentities(
                conversationId: conversationId,
                deviceIds: clientIDs)
        }
    }
}

extension WireIdentity {
    func toE2eIdenityCertificate() throws -> E2eIdentityCertificate? {
        guard let certificateData = certificate.data(using: .utf8) else {
            return nil
        }
        let x509Certificate = try X509Certificate(pem: certificateData)
        return x509Certificate.toE2eIdenityCertificate(
            clientId: clientId,
            certificateDetails: certificate,
            certificateStatus: status.e2eIdentityStatus,
            mlsThumbprint: thumbprint)
    }
}

private extension DeviceStatus {

    var e2eIdentityStatus: E2EIdentityCertificateStatus {
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

extension X509Certificate {
    func toE2eIdenityCertificate(
        clientId: String,
        certificateDetails: String,
        certificateStatus: E2EIdentityCertificateStatus,
        mlsThumbprint: String
    ) -> E2eIdentityCertificate? {
        guard let notValidBefore = notBefore,
              let notValidAfter = notAfter,
              let theSerialNumber = serialNumber?.bytes.map({ String($0, radix: 16).uppercased() }).joined(separator: "")
        else {
            return nil
        }
        return .init(
            clientId: clientId,
            certificateDetails: certificateDetails,
            mlsThumbprint: mlsThumbprint,
            notValidBefore: notValidBefore,
            expiryDate: notValidAfter,
            certificateStatus: certificateStatus,
            serialNumber: theSerialNumber)
    }
}
