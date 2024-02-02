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

// This needs to be defined at the DataModel level for visibility but needs to be
// implemented on the RequestStrategy level because of dependencies on HttpClientE2EI
public protocol CertificateRevocationListAPIProtocol {
    func getRevocationList(from distributionPoint: URL) async throws -> Data
}

public protocol CertificateRevocationListsChecking {
    func checkNewCRLs(from distributionPoints: CRLsDistributionPoints) async
    func checkExpiringCRLs() async
}

public class CertificateRevocationListsChecker: CertificateRevocationListsChecking {

    private let crlExpirationDatesRepository: CRLExpirationDatesRepositoryProtocol
    private let crlAPI: CertificateRevocationListAPIProtocol
    private let mlsConversationsVerificationUpdater: MLSConversationVerificationStatusUpdating
    private let context: NSManagedObjectContext
    private let coreCryptoProvider: CoreCryptoProviderProtocol
    private var coreCrypto: SafeCoreCryptoProtocol {
        get async throws {
            try await coreCryptoProvider.coreCrypto(requireMLS: true)
        }
    }

    public convenience init(
        userID: UUID,
        crlAPI: CertificateRevocationListAPIProtocol,
        mlsConversationsVerificationUpdater: MLSConversationVerificationStatusUpdating,
        coreCryptoProvider: CoreCryptoProviderProtocol,
        context: NSManagedObjectContext
    ) {
        self.init(
            crlAPI: crlAPI,
            crlExpirationDatesRepository: CRLExpirationDatesRepository(userID: userID),
            mlsConversationsVerificationUpdater: mlsConversationsVerificationUpdater,
            coreCryptoProvider: coreCryptoProvider,
            context: context
        )
    }
    
    init(
        crlAPI: CertificateRevocationListAPIProtocol,
        crlExpirationDatesRepository: CRLExpirationDatesRepositoryProtocol,
        mlsConversationsVerificationUpdater: MLSConversationVerificationStatusUpdating,
        coreCryptoProvider: CoreCryptoProviderProtocol,
        context: NSManagedObjectContext
    ) {
        self.crlAPI = crlAPI
        self.crlExpirationDatesRepository = crlExpirationDatesRepository
        self.mlsConversationsVerificationUpdater = mlsConversationsVerificationUpdater
        self.coreCryptoProvider = coreCryptoProvider
        self.context = context
    }

    public func checkNewCRLs(from distributionPoints: CRLsDistributionPoints) async {

        let newDistributionPoints = distributionPoints.urls.filter {
            !crlExpirationDatesRepository.crlExpirationDateExists(for: $0)
        }

        await checkCertificateRevocationLists(from: newDistributionPoints)
    }

    public func checkExpiringCRLs() async {
        let distributionPointsOfExpiringCRLs = crlExpirationDatesRepository
            .fetchAllCRLExpirationDates()
            .filter({ isCRLExpiringSoon(expirationDate: $0.value) })
            .keys

        await checkCertificateRevocationLists(from: Set(distributionPointsOfExpiringCRLs))
    }

    private func checkCertificateRevocationLists(from distributionPoints: Set<URL>) async {

        for distributionPoint in distributionPoints {
            do {
                // fetch the CRL from the distribution point
                let crlData = try await crlAPI.getRevocationList(from: distributionPoint)

                // register the CRL with core crypto
                let registration = try await coreCrypto.perform {
                    try await $0.e2eiRegisterCrl(crlDp: distributionPoint.absoluteString, crlDer: crlData)
                }

                // store the expiration time
                if let expirationTimestamp = registration.expiration {
                    let expirationDate = Date(timeIntervalSince1970: TimeInterval(expirationTimestamp))
                    crlExpirationDatesRepository.storeCRLExpirationDate(expirationDate, for: distributionPoint)
                }

                // check if certificate is "dirty"
                if registration.dirty {
                    // update verification state for conversations
                    try await mlsConversationsVerificationUpdater.updateAllStatuses()
                }
            } catch {
                // TODO: Log
                continue
            }
        }
    }

    private func isCRLExpiringSoon(expirationDate: Date) -> Bool {
        guard let oneHourBeforeExpiration = oneHourBefore(date: expirationDate) else {
           return false
        }

        return .now > oneHourBeforeExpiration
    }

    private func oneHourBefore(date: Date) -> Date? {
        Calendar.current.date(
            byAdding: .hour,
            value: -1,
            to: date
        )
    }
}
