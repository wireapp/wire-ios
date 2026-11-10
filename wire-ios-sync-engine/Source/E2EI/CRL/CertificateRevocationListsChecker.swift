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

import Foundation
import os
import WireCoreCrypto
import WireLogging

// sourcery: AutoMockable
public protocol CertificateRevocationListsChecking {
    func checkExpiredCRLs() async throws
}

public class CertificateRevocationListsChecker: CertificateRevocationListsChecking {

    // MARK: - Properties

    private let mlsGroupVerification: any MLSGroupVerificationProtocol
    private let selfClientCertificateProvider: SelfClientCertificateProviderProtocol
    private let coreCryptoProvider: CoreCryptoProviderProtocol

    private let logger = WireLogger.e2ei

    /// Whether the verification status of all conversations is currently being updated.
    private let isUpdatingVerificationStatus = OSAllocatedUnfairLock(initialState: false)

    // MARK: - Life cycle

    public init(
        mlsGroupVerification: any MLSGroupVerificationProtocol,
        selfClientCertificateProvider: SelfClientCertificateProviderProtocol,
        coreCryptoProvider: CoreCryptoProviderProtocol
    ) {
        self.mlsGroupVerification = mlsGroupVerification
        self.selfClientCertificateProvider = selfClientCertificateProvider
        self.coreCryptoProvider = coreCryptoProvider
    }

    // MARK: - Public interface

    public func checkExpiredCRLs() async throws {

        WireLogger.e2ei.info("checking expired CRLs")

        try await coreCryptoProvider.coreCrypto().transaction { context in
            try await context.checkCredentials()
        }

        // Re-evaluate the verification status in the background, regardless of whether notifying
        // about a revoked certificate below fails.
        defer {
            Task { [self] in
                await updateVerificationStatusOfAllConversations()
            }
        }

        try await notifyAboutRevokedCertificateIfNeeded()
    }

    // MARK: - Private methods

    /// CoreCrypto doesn't report which certificates changed, and epoch changes (which normally trigger a
    /// verification update) are not emitted for credential checks, so re-evaluate the verification status
    /// of all MLS conversations.
    ///
    /// Checks can run frequently (e.g. after every quick sync), so a run is skipped if a previous one is
    /// still in progress.
    private func updateVerificationStatusOfAllConversations() async {
        let didStart = isUpdatingVerificationStatus.withLock { isUpdating in
            guard !isUpdating else { return false }
            isUpdating = true
            return true
        }

        guard didStart else {
            return logger.info("skipping verification status update, already in progress")
        }

        await mlsGroupVerification.updateAllConversations()
        isUpdatingVerificationStatus.withLock { $0 = false }
    }

    private func notifyAboutRevokedCertificateIfNeeded() async throws {
        guard let certificate = try await selfClientCertificateProvider.getCertificate(),
              certificate.status == .revoked else {
            return
        }

        NotificationCenter.default.post(name: .presentRevokedCertificateWarningAlert, object: nil)
        NotificationCenter.default.post(name: .e2eiCertificateChanged, object: self)
    }

}

public extension Notification.Name {
    static let presentRevokedCertificateWarningAlert = Notification.Name("presentRevokedCertificateWarningAlert")
}
