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
import WireSyncEngine

final class DeveloperE2eiViewModel: ObservableObject {

    private let userSession: ZMUserSession?

    static let minimumCertificateExpirationTime = 360

    @Published var certificateExpirationTime = minimumCertificateExpirationTime

    @Published var storedCRLExpirationDatesByURL = [String: String]()

    @Published var certificateValidFrom = ""

    @Published var certificateValidTo = ""

    init(userSession: UserSession?) {
        self.userSession = userSession as? ZMUserSession
        Task {
            await fetchSelfClientCertificate()
        }
    }

    // MARK: - Actions

    @MainActor
    func enrollCertificate() {
        guard
            let session = userSession,
            let topmostViewController = UIApplication.shared.topmostViewController(onlyFullScreen: false)
        else { return }

        let e2eiCertificateUseCase = session.enrollE2EICertificate as? EnrollE2EICertificateUseCase
        let oauthUseCase = OAuthUseCase(targetViewController: { topmostViewController })
        let enrollmentFlow = E2EIEnrollmentFlow(
            oauthUseCase: oauthUseCase,
            targetVC: { topmostViewController }
        )

        Task { @MainActor in
            enrollmentFlow.showActivityIndicator()
            defer { enrollmentFlow.dismissActivityIndicator() }
            do {
                let expirySec = UInt32(certificateExpirationTime)
                guard let certificateDetails = try await e2eiCertificateUseCase?.invoke(
                    authenticate: enrollmentFlow.authenticate,
                    expirySec: expirySec
                ) else { return }

                enrollmentFlow.dismissActivityIndicator()

                let successVC = SuccessfulCertificateEnrollmentViewController()
                successVC.certificateDetails = certificateDetails
                successVC.onOkTapped = { viewController in
                    viewController.dismiss(animated: true)
                }
                successVC.presentOverAll()
            } catch {
                WireLogger.e2ei.error("failed to enroll e2ei: \(error)")
            }
        }
    }

    @MainActor
    func showUpdateCertificateAlert(canRemindLater: Bool) {
        typealias E2EIUpdateStrings = L10n.Localizable.UpdateCertificate.Alert

        guard let developerToolsViewController = UIApplication.shared.topmostViewController(onlyFullScreen: false)
        else {
            return
        }

        developerToolsViewController.dismiss(animated: true) {
            guard let presentingViewController = UIApplication.shared.topmostViewController(onlyFullScreen: false)
            else {
                return
            }

            let alert = UIAlertController.alertForE2EIChangeWithActions(
                title: E2EIUpdateStrings.title,
                message: canRemindLater ? E2EIUpdateStrings.message : E2EIUpdateStrings.expiredMessage,
                enrollButtonText: E2EIUpdateStrings.title,
                canRemindLater: canRemindLater
            ) { action in
                switch action {
                case .getCertificate:
                    self.enrollCertificate()
                case .remindLater, .learnMore:
                    break
                }
            }

            presentingViewController.present(alert, animated: true)
        }
    }

    @MainActor
    func fetchSelfClientCertificate() async {
        guard let session = userSession,
              let certificate = try? await session.selfClientCertificateProvider.getCertificate()
        else {
            return
        }

        certificateValidFrom = dateFormatter.string(from: certificate.notValidBefore)
        certificateValidTo = dateFormatter.string(from: certificate.expiryDate)
    }

    // MARK: - Helper

    private var dateFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium

        return dateFormatter
    }

}
