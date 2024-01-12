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
    public var certificateStatus: E2EIdentityCertificateStatus
    public var serialNumber: String

    public init(
        certificateDetails: String,
        mlsThumbprint: String,
        notValidBefore: Date,
        expiryDate: Date,
        certificateStatus: E2EIdentityCertificateStatus,
        serialNumber: String
    ) {
        self.certificateDetails = certificateDetails
        self.mlsThumbprint = mlsThumbprint
        self.notValidBefore = notValidBefore
        self.expiryDate = expiryDate
        self.certificateStatus = certificateStatus
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
           self.certificateStatus = certificateStatus
           self.mlsThumbprint = mlsThumbprint
       }
}

public protocol E2eIdentityProviding {
    func isE2EIdentityEnabled() async throws -> Bool
    func fetchCertificates(clientIds: [Data]) async throws -> [E2eIdentityCertificate]
    func fetchCertificates(userIds: [String]) async throws -> [String: [E2eIdentityCertificate]]
    func shouldUpdateCertificate(for certificate: E2eIdentityCertificate) -> Bool
}

enum E2eIdentityCertificateError: Error {
    case badCertificate
}

public final class E2eIdentityProvider: E2eIdentityProviding {

    // current default days the certificate is retained on server
    private let kServerRetainedDays: Double = 28 * 24 * 60 * 60

    // Randomising time so that not all clients update certificate at the same time
    private let kRandomInterval = Int.random(in: 0..<86400)

    // Grace period fromt he E2ei config settings
    private let gracePeriod: Double
    private let coreCryptoProvider: CoreCryptoProviderProtocol
    private let context: NSManagedObjectContext

    public init(
        gracePeriod: Double,
        coreCryptoProvider: CoreCryptoProviderProtocol,
        context: NSManagedObjectContext // make sure to run on SyncContext
    ) {
        self.gracePeriod = gracePeriod
        self.coreCryptoProvider = coreCryptoProvider
        self.context = context
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

    public func shouldUpdateCertificate(for certificate: E2eIdentityCertificate) -> Bool {
        guard  certificate.notValidBefore >= Date.now  else {
            return false
        }
        var remainingTimeToUpdate = DateInterval(start: Date.now, end: certificate.expiryDate).duration
        remainingTimeToUpdate -= gracePeriod - Double(kServerRetainedDays) - Double(kRandomInterval)
        return remainingTimeToUpdate <= 0.0
    }

    private func fetchWireIdentity(clientIDs: [ClientId]) async throws -> [WireIdentity] {
        guard let conversationId = await fetchSelfConversation() else {
            return []
        }
        return try await coreCrypto.perform {
            return try await $0.getDeviceIdentities(conversationId: conversationId, deviceIds: clientIDs)
        }
    }

    private func fetchWireIdentity(userIds: [String]) async throws -> [String: [WireIdentity]] {
        guard let converstionId = await fetchSelfConversation() else {
            return [:]
        }
        return try await coreCrypto.perform {
           return try await $0.getUserIdentities(conversationId: converstionId, userIds: userIds)
        }
    }

    private func fetchSelfConversation() async -> Data? {
       return await context.perform {
            return ZMConversation.fetchSelfMLSConversation(in: self.context)?.mlsGroupID?.data
        }
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
