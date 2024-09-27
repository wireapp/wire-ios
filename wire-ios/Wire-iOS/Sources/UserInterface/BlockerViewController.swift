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

import MessageUI
import UIKit
import WireSyncEngine

// MARK: - BlockerViewControllerContext

enum BlockerViewControllerContext {
    case blacklist
    case jailbroken
    case databaseFailure
    case backendNotSupported
    case pendingCertificateEnroll
}

// MARK: - BlockerViewController

final class BlockerViewController: LaunchImageViewController {
    private var context: BlockerViewControllerContext = .blacklist
    private var error: Error?
    private var sessionManager: SessionManager?

    private var observerTokens = [Any]()

    init(context: BlockerViewControllerContext, sessionManager: SessionManager? = nil, error: Error? = nil) {
        self.error = error
        self.context = context
        self.sessionManager = sessionManager
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init?(coder aDecoder: NSCoder) is not implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupApplicationNotifications()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showAlert()
    }

    func showAlert() {
        switch context {
        case .blacklist:
            showBlacklistMessage()
        case .jailbroken:
            showJailbrokenMessage()
        case .databaseFailure:
            showDatabaseFailureMessage()
        case .backendNotSupported:
            showBackendNotSupportedMessage()
        case .pendingCertificateEnroll:
            showGetCertificateMessage()
        }
    }

    private func showBackendNotSupportedMessage() {
        typealias BackendNotSupported = L10n.Localizable.BackendNotSupported.Alert

        presentOKAlert(
            title: BackendNotSupported.title,
            message: BackendNotSupported.message
        )
    }

    private func showBlacklistMessage() {
        presentOKAlert(
            title: L10n.Localizable.Force.Update.title,
            message: L10n.Localizable.Force.Update.message
        ) { _ in
            UIApplication.shared.open(WireURLs.shared.appOnItunes)
        }
    }

    private func showJailbrokenMessage() {
        presentOKAlert(
            title: L10n.Localizable.Jailbrokendevice.Alert.title,
            message: L10n.Localizable.Jailbrokendevice.Alert.message
        )
    }

    private func presentOKAlert(
        title: String,
        message: String,
        handler: ((UIAlertAction) -> Void)? = nil
    ) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(
            title: L10n.Localizable.General.ok,
            style: .cancel,
            handler: handler
        ))

        present(alert, animated: true)
    }

    private func showGetCertificateMessage() {
        typealias E2EI = L10n.Localizable.Registration.Signin.E2ei

        let getCertificateAlert = UIAlertController(
            title: E2EI.title,
            message: E2EI.subtitle,
            preferredStyle: .alert
        )

        let learnMoreAction = UIAlertAction(
            title: L10n.Localizable.FeatureConfig.Alert.MlsE2ei.Button.learnMore,
            style: .default,
            handler: { _ in
                UIApplication.shared.open(WireURLs.shared.endToEndIdentityInfo)
            }
        )

        let getCertificateAction = UIAlertAction(
            title: E2EI.GetCertificateButton.title,
            style: .default,
            handler: { [weak self] _ in
                Task {
                    await self?.enrollCertificateAction()
                }
            }
        )

        getCertificateAlert.addAction(learnMoreAction)
        getCertificateAlert.addAction(getCertificateAction)
        present(getCertificateAlert, animated: true)
    }

    private func showDatabaseFailureMessage() {
        let message = L10n.Localizable.Databaseloadingfailure.Alert.message(error?.localizedDescription ?? "-")

        let databaseFailureAlert = UIAlertController(
            title: L10n.Localizable.Databaseloadingfailure.Alert.title,
            message: message,
            preferredStyle: .alert
        )

        let reportError = UIAlertAction(
            title: L10n.Localizable.Self.Settings.TechnicalReport.sendReport,
            style: .default
        ) { [weak self] _ in
            guard let self else { return }
            let fallbackActivityPopoverConfiguration = PopoverPresentationControllerConfiguration.sourceView(
                sourceView: view,
                sourceRect: .init(origin: view.safeAreaLayoutGuide.layoutFrame.origin, size: .zero)
            )
            presentMailComposer(fallbackActivityPopoverConfiguration: fallbackActivityPopoverConfiguration)
        }

        databaseFailureAlert.addAction(reportError)

        let retryAction = UIAlertAction(
            title: L10n.Localizable.Databaseloadingfailure.Alert.retry,
            style: .default
        ) { [weak self] _ in
            self?.sessionManager?.retryStart()
        }

        databaseFailureAlert.addAction(retryAction)

        let deleteDatabaseAction = UIAlertAction(
            title: L10n.Localizable.Databaseloadingfailure.Alert.deleteDatabase,
            style: .destructive
        ) { [weak self] _ in
            self?.dismiss(animated: true) {
                self?.showConfirmationDatabaseDeletionAlert()
            }
        }

        databaseFailureAlert.addAction(deleteDatabaseAction)
        present(databaseFailureAlert, animated: true)
    }

    private func showConfirmationDatabaseDeletionAlert() {
        let deleteDatabaseConfirmationAlert = UIAlertController(
            title: L10n.Localizable.Databaseloadingfailure.Alert.deleteDatabase,
            message: L10n.Localizable.Databaseloadingfailure.Alert.DeleteDatabase.message,
            preferredStyle: .alert
        )

        let continueAction = UIAlertAction(
            title: L10n.Localizable.Databaseloadingfailure.Alert.DeleteDatabase.continue,
            style: .destructive,
            handler: { [weak self] _ in
                self?.sessionManager?.removeDatabaseFromDisk()
            }
        )

        deleteDatabaseConfirmationAlert.addAction(continueAction)

        let cancelAction = UIAlertAction(
            title: L10n.Localizable.General.cancel,
            style: .default,
            handler: { [weak self] _ in
                self?.showDatabaseFailureMessage()
            }
        )

        deleteDatabaseConfirmationAlert.addAction(cancelAction)
        present(deleteDatabaseConfirmationAlert, animated: true)
    }

    func mailComposeController(
        _ controller: MFMailComposeViewController,
        didFinishWith result: MFMailComposeResult,
        error: Error?
    ) {
        // shown after sending report logs, we should show other choices again
        // in order not to be stuck on black screen
        controller.presentingViewController?.dismiss(animated: true) {
            self.showDatabaseFailureMessage()
        }
    }
}

// MARK: ApplicationStateObserving

extension BlockerViewController: ApplicationStateObserving {
    func addObserverToken(_ token: NSObjectProtocol) {
        observerTokens.append(token)
    }

    func applicationDidBecomeActive() {
        showAlert()
    }
}

// MARK: SendTechnicalReportPresenter

extension BlockerViewController: SendTechnicalReportPresenter {}

// MARK: - Certificate enrollment

extension BlockerViewController {
    private func enrollCertificateAction() async {
        do {
            try await enrollCertificate()
            sessionManager?.didEnrollCertificateSuccessfully()
        } catch {
            WireLogger.e2ei.warn("failed to enroll certificate: \(error)")

            let alert = UIAlertController.getCertificateFailed(canCancel: false, isUpdateMode: false) {
                Task {
                    await self.enrollCertificateAction()
                }
            } cancelled: {}
        }
    }

    private func enrollCertificate() async throws {
        guard
            let activeUserSession = sessionManager?.activeUserSession,
            let rootViewController = AppDelegate.shared.mainWindow.rootViewController
        else {
            return
        }
        let oauthUseCase = OAuthUseCase(targetViewController: { rootViewController })

        let certificateChain = try await activeUserSession
            .enrollE2EICertificate
            .invoke(authenticate: oauthUseCase.invoke)

        let successEnrollmentViewController = SuccessfulCertificateEnrollmentViewController()
        successEnrollmentViewController.certificateDetails = certificateChain
        successEnrollmentViewController.onOkTapped = { viewController in
            viewController.dismiss(animated: true)
        }
        successEnrollmentViewController.presentTopmost()
    }
}
