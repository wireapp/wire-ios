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
import X509
import SwiftASN1

// sourcery: AutoMockable
public protocol GetE2eIdentityCertificatesUseCaseProtocol {
    func invoke(conversationId: Data,
                clientIds: [WireDataModel.MLSClientID]) async throws -> [WireDataModel.E2eIdentityCertificate]
}

final public class GetE2eIdentityCertificatesUseCase: GetE2eIdentityCertificatesUseCaseProtocol {
    private let coreCryptoProvider: CoreCryptoProviderProtocol

    public init(coreCryptoProvider: CoreCryptoProviderProtocol) {
        self.coreCryptoProvider = coreCryptoProvider
    }

    public func invoke(conversationId: Data,
                       clientIds: [WireDataModel.MLSClientID]) async throws -> [WireDataModel.E2eIdentityCertificate] {
        let coreCrypto = try await coreCryptoProvider.coreCrypto(requireMLS: true)
        let clientIds = clientIds.compactMap({ $0.clientID.data(using: .utf8)})
        let wireIdentities = try await getWireIdentity(coreCrypto: coreCrypto, conversationId: conversationId, clientIDs: clientIds)
        if wireIdentities.count == 0 {
            return Array(repeating: .notActivated, count: clientIds.count)
        } else {
            return try wireIdentities.map({
                try $0.toE2eIdenityCertificate()
            })
        }
    }

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

    func toE2eIdenityCertificate() throws -> E2eIdentityCertificate {
        let pemDocument = try PEMDocument(pemString: self.certificate)
        let certificate = try Certificate(pemDocument: pemDocument)
        return E2eIdentityCertificate(
            certificate: certificate,
            certificateDetails: self.certificate,
            certificateStatus: self.status.e2eIdentityStatus,
            mlsThumbprint: self.thumbprint
        )
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

extension E2eIdentityCertificate {
    static var notActivated: E2eIdentityCertificate {
        E2eIdentityCertificate(
            certificateDetails: "",
            mlsThumbprint: "",
            notValidBefore: .now,
            expiryDate: .now,
            certificateStatus: .notActivated,
            serialNumber: ""
        )
    }
}
