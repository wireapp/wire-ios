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

// sourcery: AutoMockable
public protocol CertificateRevocationListsChecking {
    func checkNewCRLs(from distributionPoints: CRLsDistributionPoints) async
    func checkExpiredCRLs() async
}

public class CertificateRevocationListsChecker: CertificateRevocationListsChecking {

    // MARK: - Properties

    private let crlExpirationDatesRepository: CRLExpirationDatesRepositoryProtocol
    private let crlAPI: CertificateRevocationListAPIProtocol
    private let mlsConversationsVerificationUpdater: MLSConversationVerificationStatusUpdating
    private let selfClientCertificateProvider: SelfClientCertificateProviderProtocol
    private let context: NSManagedObjectContext
    private let coreCryptoProvider: CoreCryptoProviderProtocol
    private var coreCrypto: SafeCoreCryptoProtocol {
        get async throws {
            try await coreCryptoProvider.coreCrypto()
        }
    }

    private let logger = WireLogger.e2ei

    // MARK: - Life cycle

    public convenience init(
        userID: UUID,
        crlAPI: CertificateRevocationListAPIProtocol,
        mlsConversationsVerificationUpdater: MLSConversationVerificationStatusUpdating,
        selfClientCertificateProvider: SelfClientCertificateProviderProtocol,
        coreCryptoProvider: CoreCryptoProviderProtocol,
        context: NSManagedObjectContext
    ) {
        self.init(
            crlAPI: crlAPI,
            crlExpirationDatesRepository: CRLExpirationDatesRepository(userID: userID),
            mlsConversationsVerificationUpdater: mlsConversationsVerificationUpdater,
            selfClientCertificateProvider: selfClientCertificateProvider,
            coreCryptoProvider: coreCryptoProvider,
            context: context
        )
    }

    init(
        crlAPI: CertificateRevocationListAPIProtocol,
        crlExpirationDatesRepository: CRLExpirationDatesRepositoryProtocol,
        mlsConversationsVerificationUpdater: MLSConversationVerificationStatusUpdating,
        selfClientCertificateProvider: SelfClientCertificateProviderProtocol,
        coreCryptoProvider: CoreCryptoProviderProtocol,
        context: NSManagedObjectContext
    ) {
        self.crlAPI = crlAPI
        self.crlExpirationDatesRepository = crlExpirationDatesRepository
        self.mlsConversationsVerificationUpdater = mlsConversationsVerificationUpdater
        self.selfClientCertificateProvider = selfClientCertificateProvider
        self.coreCryptoProvider = coreCryptoProvider
        self.context = context
    }

    // MARK: - Public interface

    public func checkNewCRLs(from distributionPoints: CRLsDistributionPoints) async {

        let newDistributionPoints = distributionPoints.urls.filter {
            !crlExpirationDatesRepository.crlExpirationDateExists(for: $0)
        }

        await checkCertificateRevocationLists(from: newDistributionPoints)
    }

    public func checkExpiredCRLs() async {

        WireLogger.e2ei.info("checking expired CRLs")

        let distributionPointsOfExpiringCRLs = crlExpirationDatesRepository
            .fetchAllCRLExpirationDates()
            .filter {
                // We give 10 seconds delay to allow time for the certificate to be renewed by the server
                // see https://wearezeta.atlassian.net/wiki/spaces/ENGINEERIN/pages/950010018/Use+case+revocation+expiration+of+an+E2EI+certificate
                hasCRLExpiredAtLeastTenSecondsAgo(expirationDate: $0.value)
            }
            .keys

        await checkCertificateRevocationLists(from: Set(distributionPointsOfExpiringCRLs))
    }

    // MARK: - Private methods

    private func checkCertificateRevocationLists(from distributionPoints: Set<URL>) async {

        var shouldNotifyAboutRevokedCertificate = false
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
                    await mlsConversationsVerificationUpdater.updateAllStatuses()

                    shouldNotifyAboutRevokedCertificate = true

                }
            } catch {
                logger.warn("failed to check certificate revocation list: (error: \(error), distributionPoint: \(distributionPoint))")
            }
        }

        if shouldNotifyAboutRevokedCertificate {
            await notifyAboutRevokedCertificateIfNeeded()
        }
    }

    private func hasCRLExpiredAtLeastTenSecondsAgo(expirationDate: Date) -> Bool {
        guard let tenSecondsAfterExpiration = tenSecondsAfter(date: expirationDate) else {
            return expirationDate.isInThePast
        }

        return tenSecondsAfterExpiration.isInThePast
    }

    private func tenSecondsAfter(date: Date) -> Date? {
        Calendar.current.date(
            byAdding: .second,
            value: 10,
            to: date
        )
    }

    private func notifyAboutRevokedCertificateIfNeeded() async {
        do {
            guard let certificate = try await selfClientCertificateProvider.getCertificate(),
                  certificate.status == .revoked else {
                return
            }
            NotificationCenter.default.post(name: .presentRevokedCertificateWarningAlert, object: nil)
        } catch {
            logger.warn("failed to fetch certificate for self client: \(error)")
        }

    }

}

public extension Notification.Name {
    static let presentRevokedCertificateWarningAlert = Notification.Name("presentRevokedCertificateWarningAlert")
}
