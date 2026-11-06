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
import WireCoreCrypto
import WireLogging

// sourcery: AutoMockable
public protocol CertificateRevocationListsChecking {
    func checkExpiredCRLs() async
}

public class CertificateRevocationListsChecker: CertificateRevocationListsChecking {

    // MARK: - Properties

    private let selfClientCertificateProvider: SelfClientCertificateProviderProtocol
    private let coreCryptoProvider: CoreCryptoProviderProtocol

    private let logger = WireLogger.e2ei

    // MARK: - Life cycle

    public init(
        selfClientCertificateProvider: SelfClientCertificateProviderProtocol,
        coreCryptoProvider: CoreCryptoProviderProtocol
    ) {
        self.selfClientCertificateProvider = selfClientCertificateProvider
        self.coreCryptoProvider = coreCryptoProvider
    }

    // MARK: - Public interface

    public func checkExpiredCRLs() async {

        WireLogger.e2ei.info("checking expired CRLs")

        do {
            try await coreCryptoProvider.coreCrypto().transaction { context in
                try await context.checkCredentials()
            }

            await notifyAboutRevokedCertificateIfNeeded()
        } catch {
            logger.warn("failed to check credentials: \(error)")
        }
    }

    // MARK: - Private methods

    private func notifyAboutRevokedCertificateIfNeeded() async {
        do {
            guard let certificate = try await selfClientCertificateProvider.getCertificate(),
                  certificate.status == .revoked else {
                return
            }

            NotificationCenter.default.post(name: .presentRevokedCertificateWarningAlert, object: nil)
            NotificationCenter.default.post(name: .e2eiCertificateChanged, object: self)
        } catch {
            logger.warn("failed to fetch certificate for self client: \(error)")
        }

    }

}

public extension Notification.Name {
    static let presentRevokedCertificateWarningAlert = Notification.Name("presentRevokedCertificateWarningAlert")
}
