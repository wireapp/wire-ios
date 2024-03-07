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
import WireSyncEngine

final class DeveloperE2eiViewModel: ObservableObject {

    private var userSession: ZMUserSession? { ZMUserSession.shared() }
    private var crlExpirationDatesRepository: CRLExpirationDatesRepository? {
        guard let userSession else { return nil }
        return CRLExpirationDatesRepository(userID: userSession.selfUser.remoteIdentifier)
    }

    @Published
    var certificateExpirationTime = ""

    @Published
    var storedCRLExpirationDatesByURL = [String: String]()

    init() {
        refreshCRLExpirationDates()
    }

    // MARK: - Actions

    func enrollCertificate() {
        guard
            let session = userSession,
            let rootViewController = AppDelegate.shared.window?.rootViewController
        else { return }

        let e2eiCertificateUseCase = session.enrollE2EICertificate as? EnrollE2EICertificateUseCase
        let oauthUseCase = OAuthUseCase(rootViewController: rootViewController)

        Task {
            do {
                let expirySec = UInt32(certificateExpirationTime)
                _ = try await e2eiCertificateUseCase?.invoke(
                    authenticate: oauthUseCase.invoke,
                    expirySec: expirySec
                )
            } catch {
                WireLogger.e2ei.error("failed to enroll e2ei: \(error)")
            }
        }
    }

    func removeAllExpirationDates() {
        guard let crlExpirationDatesRepository else { return }

        crlExpirationDatesRepository.removeAllExpirationDates()
        refreshCRLExpirationDates()
    }

    func refreshCRLExpirationDates() {
        guard let crlExpirationDatesRepository else { return }

        let expirationDates = crlExpirationDatesRepository.fetchAllCRLExpirationDates()

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium

        var formattedExpiratioDates = [String: String]()

        for (url, date) in expirationDates {
            let urlString = url.absoluteString
            let dateString = dateFormatter.string(from: date)
            formattedExpiratioDates[urlString] = dateString
        }

        storedCRLExpirationDatesByURL = formattedExpiratioDates
    }

}
