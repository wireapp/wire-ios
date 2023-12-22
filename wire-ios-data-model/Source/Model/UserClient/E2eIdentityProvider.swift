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
import X509
import SwiftASN1
import WireCoreCrypto

public enum E2EIdentityCertificateStatus: CaseIterable {
    case notActivated, revoked, expired, valid
}

public struct E2eIdentityCertificate {
    public var certificateDetails: String
    public var mlsThumbprint: String
    public var notValidBefore: Date
    public var expiryDate: Date
    public var status: E2EIdentityCertificateStatus
    public var serialNumber: String

    public init(
        certificateDetails: String,
        mlsThumbprint: String,
        notValidBefore: Date,
        expiryDate: Date,
        status: E2EIdentityCertificateStatus,
        serialNumber: String
    ) {
        self.certificateDetails = certificateDetails
        self.mlsThumbprint = mlsThumbprint
        self.expiryDate = expiryDate
        self.notValidBefore = notValidBefore
        self.status = status
        self.serialNumber = serialNumber
    }

    public init(
        certificate: Certificate,
        certificateDetails: String,
        certificateStatus: E2EIdentityCertificateStatus,
        mlsThumbprint: String
    ) {
        self.certificateDetails = certificateDetails
        self.notValidBefore = certificate.notValidBefore
        self.expiryDate = certificate.notValidAfter
        self.serialNumber = certificate.serialNumber.description.replacingOccurrences(of: ":", with: "")
        self.status = certificateStatus
        self.mlsThumbprint = mlsThumbprint
    }
}

public protocol E2eIdentityProviding {
    func isE2EIdentityEnabled() -> Bool
    func fetchCertificates() async throws -> [E2eIdentityCertificate]
    func shouldUpdateCertificate(for certificate: E2eIdentityCertificate) -> Bool
}

// TODO: remove this once updated Core-crypto is available
public extension WireIdentity {

    var status: E2EIdentityCertificateStatus {
        .valid
    }

    var certificate: String {
        .mockCertificate()
    }

    var thumbprint: String {
        return .mockThumbprint()
    }

}

public final class E2eIdentityProvider: E2eIdentityProviding {

    private let kServerRetainedDays: Double = 28 * 24 * 60 * 60
    private let kRandomInterval = Int.random(in: 0..<86400)

    private var clientIds: [ClientId]?
    private var userIds: [String]?
    private var conversationId: String
    private var gracePeriod: Double
    private var cryptoProvider: CryptoE2EIdentityProviderProtocol

    public init(
        clientIds: [ClientId]?,
        userIds: [String]?,
        conversationId: String,
        gracePeriod: Double,
        cryptoProvider: CryptoE2EIdentityProviderProtocol = MockCryptoE2EIProvider()
    ) {
        self.clientIds = clientIds
        self.userIds = userIds
        self.conversationId = conversationId
        self.gracePeriod = gracePeriod
        self.cryptoProvider = cryptoProvider
    }

    public func isE2EIdentityEnabled() -> Bool {
        // TODO: call core crypto method to get E2EI status
        return cryptoProvider.isE2EIdentityEnabled()
    }

    public func fetchCertificates() async throws -> [E2eIdentityCertificate] {
        var wireIdentities = [WireIdentity]()
        if let clientIds = clientIds {
            wireIdentities = fetchWireIdentity(clientIDs: clientIds, conversationId: conversationId)
        }
        if let userIds = userIds {
            wireIdentities = fetchWireIdentity(userIds: userIds, conversationId: conversationId)
        }
        var e2eiCertificates = [E2eIdentityCertificate]()
        for wireIdentity in wireIdentities {
            let pemDocument = try PEMDocument(pemString: wireIdentity.certificate)
            let certificate = try Certificate(pemDocument: pemDocument)
            let e2eiCertificate = E2eIdentityCertificate(
                certificate: certificate,
                certificateDetails: wireIdentity.certificate,
                certificateStatus: wireIdentity.status,
                mlsThumbprint: wireIdentity.thumbprint
            )
            e2eiCertificates.append(e2eiCertificate)
        }
        return e2eiCertificates
    }

    public func shouldUpdateCertificate(for certificate: E2eIdentityCertificate) -> Bool {
        // TODO: call core cypto function to check the validity. Check if the certificate was revoked
        let validationInterval = DateInterval(
            start: certificate.notValidBefore,
            end: certificate.expiryDate).duration
        let remainingTimeToUpdate = validationInterval
        - gracePeriod
        - Double(kServerRetainedDays)
        - Double(kRandomInterval)
        return remainingTimeToUpdate <= 0.0
    }

    private func fetchWireIdentity(clientIDs: [ClientId], conversationId: String) -> [WireIdentity] {
        return cryptoProvider.fetchWireIdentity(clientIDs: clientIDs, conversationId: conversationId)
    }

    private func fetchWireIdentity(userIds: [String], conversationId: String ) -> [WireIdentity] {
        return cryptoProvider.fetchWireIdentity(userIds: userIds, conversationId: conversationId)
    }
}
