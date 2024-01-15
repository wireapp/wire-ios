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
    public var details: String
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
        certificateStatus: E2EIdentityCertificateStatus,
        serialNumber: String
    ) {
        self.details = certificateDetails
        self.mlsThumbprint = mlsThumbprint
        self.notValidBefore = notValidBefore
        self.expiryDate = expiryDate
        self.status = certificateStatus
        self.serialNumber = serialNumber
    }

    public init(
           certificate: Certificate,
           certificateDetails: String,
           certificateStatus: E2EIdentityCertificateStatus,
           mlsThumbprint: String
       ) {
           self.details = certificateDetails
           self.notValidBefore = certificate.notValidBefore
           self.expiryDate = certificate.notValidAfter
           self.serialNumber = certificate.serialNumber.description.replacingOccurrences(of: ":", with: "")
           self.status = certificateStatus
           self.mlsThumbprint = mlsThumbprint
       }
}

public protocol E2eIdentityProviding {
    func isE2EIdentityEnabled() async throws -> Bool
    func fetchCertificates(clientIds: [Data]) async throws -> [E2eIdentityCertificate]
    func fetchCertificates(userIds: [String]) async throws -> [String: [E2eIdentityCertificate]]
    func shouldCertificateBeUpdated(for certificate: E2eIdentityCertificate) -> Bool
}

enum E2eIdentityCertificateError: Error {
    case badCertificate
}

public final class E2eIdentityProvider: E2eIdentityProviding {

    // Grace period fromt he E2ei config settings
    private let gracePeriod: Double
    private let coreCryptoProvider: CoreCryptoProviderProtocol
    private let conversationId: Data

    public init(
        gracePeriod: Double,
        coreCryptoProvider: CoreCryptoProviderProtocol,
        conversationId: Data // make sure to run on SyncContext
    ) {
        // TODO: precondition(zm_isSyncContext, "MLSService should only be accessed on the sync context")
        self.gracePeriod = gracePeriod
        self.coreCryptoProvider = coreCryptoProvider
        self.conversationId = conversationId
    }

    var coreCrypto: SafeCoreCryptoProtocol {
        get async throws {
           try await coreCryptoProvider.coreCrypto(requireMLS: true)
        }
    }
    public func isE2EIdentityEnabled() async throws -> Bool {
        try await coreCrypto.perform {
             try await $0.e2eiIsEnabled(ciphersuite: CiphersuiteName.default.rawValue)
        }
    }

    public func fetchCertificates(clientIds: [Data]) async throws -> [E2eIdentityCertificate] {
        let wireIdentities = try await fetchWireIdentity(clientIDs: clientIds)
        // TODO: Ask Mojtaba about Not Activated Device status
        return try wireIdentities.map({
            try $0.mapToE2eIdenityCertificate()
        })
    }

    public func fetchCertificates(userIds: [String]) async throws -> [String: [E2eIdentityCertificate]] {
        let wireIdentities = try await fetchWireIdentity(userIds: userIds)
        return try wireIdentities.mapValues({
            try $0.map({
                try $0.mapToE2eIdenityCertificate()
            })
        })
    }

    public func shouldCertificateBeUpdated(for certificate: E2eIdentityCertificate) -> Bool {
        guard  certificate.isActivated,
                certificate.isExpired,
               (certificate.lastUpdatedDate + gracePeriod) < Date.now else {
            return false
        }
        return true
    }

    private func fetchWireIdentity(clientIDs: [ClientId]) async throws -> [WireIdentity] {
        return try await coreCrypto.perform {
            return try await $0.getDeviceIdentities(conversationId: self.conversationId, deviceIds: clientIDs)
        }
    }

    private func fetchWireIdentity(userIds: [String]) async throws -> [String: [WireIdentity]] {
        return try await coreCrypto.perform {
            return try await $0.getUserIdentities(conversationId: self.conversationId, userIds: userIds)
        }
    }
}

private extension E2eIdentityCertificate {
    // current default days the certificate is retained on server
    private var kServerRetainedDays: Double { 28 * 24 * 60 * 60 }

    // Randomising time so that not all clients update certificate at the same time
    private var kRandomInterval: Double { Double(Int.random(in: 0..<86400)) }

    var isExpired: Bool {
        return expiryDate > Date.now
    }

    var isActivated: Bool {
        return notValidBefore <= Date.now
    }

    var lastUpdatedDate: Date {
        return notValidBefore + kServerRetainedDays + kRandomInterval
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
            return .notActivated
        }
    }

}

private extension WireIdentity {

    func mapToE2eIdenityCertificate() throws -> E2eIdentityCertificate {
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
