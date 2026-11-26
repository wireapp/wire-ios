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

    func setupE2EICredentialsChecker(mlsGroupVerification: any MLSGroupVerificationProtocol) {
        let credentialsChecker = E2EICredentialsChecker(
            mlsGroupVerification: mlsGroupVerification,
            selfClientCertificateProvider: selfClientCertificateProvider,
            coreCryptoProvider: coreCryptoProvider
        )
        self.credentialsChecker = credentialsChecker
    }

    func checkE2EICredentialsInBackground() {
        Task {
            do {
                try await checkE2EICredentials()
            } catch {
                WireLogger.e2ei.warn("failed to check E2EI credentials: \(error)")
            }
        }
    }

    /// Asks the CRL checker to re-check all credentials, if the E2EI feature is enabled.
    ///
    /// - Throws: Any error raised while checking the credentials.
    public func checkE2EICredentials() async throws {
        guard let credentialsChecker else {
            WireLogger.e2ei.error("requires 'credentialsChecker' to check E2EI credentials!", attributes: .safePublic)
            return
        }

        let isE2EIFeatureEnabled = await managedObjectContext.perform { self.e2eiFeature.isEnabled }
        guard isE2EIFeatureEnabled else { return }

        try await credentialsChecker.checkCredentials()
    }
}
