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
import WireLogging

extension ZMUserSession {

    func setupCertificateRevocationLists(mlsGroupVerification: any MLSGroupVerificationProtocol) {
        let cRLsChecker = CertificateRevocationListsChecker(
            mlsGroupVerification: mlsGroupVerification,
            selfClientCertificateProvider: selfClientCertificateProvider,
            coreCryptoProvider: coreCryptoProvider
        )
        self.cRLsChecker = cRLsChecker
    }

    func checkExpiredCertificateRevocationLists() {
        Task {
            do {
                try await refreshCertificateRevocationLists()
            } catch {
                WireLogger.e2ei.warn("failed to check expired CRLs: \(error)")
            }
        }
    }

    /// Asks the CRL checker to re-check all credentials, if the E2EI feature is enabled.
    ///
    /// - Throws: Any error raised while checking the credentials.
    public func refreshCertificateRevocationLists() async throws {
        guard let cRLsChecker else {
            WireLogger.e2ei.error("requires 'cRLsChecker' to refresh CRLs!", attributes: .safePublic)
            return
        }

        let isE2EIFeatureEnabled = await managedObjectContext.perform { self.e2eiFeature.isEnabled }
        guard isE2EIFeatureEnabled else { return }

        try await cRLsChecker.checkExpiredCRLs()
    }
}
