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

import UIKit
import WireLocators
import WireLogging
import WireMultiBackendUI
import WireSyncEngine

final class BlockerViewController: LaunchImageViewController {
    private let viewModel: BlockerViewModel
    private var sessionManager: SessionManager?
    private let shareDebugPresenter = ShareDebugReportPresenter()

    private var observerTokens = [Any]()

    init(context: BlockerViewControllerContext, sessionManager: SessionManager? = nil, error: Error? = nil) {
        self.viewModel = BlockerViewModel(context: context, error: error)
        self.sessionManager = sessionManager
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init?(coder aDecoder: NSCoder) is not implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.accessibilityIdentifier = Locators.BlockerPage.mainContent.rawValue
        setupApplicationNotifications()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showAlert()
    }

    func showAlert() {
        switch viewModel.route(capabilities: capabilities) {
        case .obsoleteClient:
            presentObsoleteClientAlert()
        case .obsoleteServer:
            presentObsoleteServerAlert()
        case let .alert(alertState):
            present(alertState: alertState)
        }
    }

    private func presentObsoleteServerAlert() {
        let alert = MultibackendAlertMainApp.obsoleteServer(
            switchAccountAction: switchAccountAction,
            logoutAction: handleLogout
        )

        present(alert, animated: true)
    }

    private func presentObsoleteClientAlert() {
        let alert = MultibackendAlertMainApp.obsoleteClient(
            updateAction: { UIApplication.shared.open(WireURLs.shared.appOnItunes) },
            switchAccountAction: switchAccountAction,
            logoutAction: handleLogout
        )

        present(alert, animated: true)
    }

    private func present(alertState: BlockerViewModel.AlertState) {
        let alert = UIAlertController(
            title: alertState.title,
            message: alertState.message,
            preferredStyle: .alert
        )

        alertState.actions.forEach { actionState in
            alert.addAction(
                UIAlertAction(
                    title: actionState.title,
                    style: actionState.style.uiAlertActionStyle
                ) { [weak self] _ in
                    self?.perform(actionState.kind)
                }
            )
        }

        present(alert, animated: true)
    }

    private var capabilities: BlockerViewModel.Capabilities {
        .init(
            canSwitchAccounts: switchAccountAction != nil,
            hasSelectedAccount: sessionManager?.accountManager.selectedAccount != nil
        )
    }

    private func perform(_ action: BlockerViewModel.ActionKind) {
        switch action {
        case .ok:
            break
        case .switchAccount:
            switchAccountAction?()
        case .sendLogs:
            shareDebugPresenter.present(from: self)
        case .signOut:
            guard let account = sessionManager?.accountManager.selectedAccount else { return }
            sessionManager?.logout(account: account)
        case .retrySelectedAccount:
            guard let account = sessionManager?.accountManager.selectedAccount else { return }
            sessionManager?.select(account)
        case .retryStart:
            sessionManager?.retryStart()
        case .requestDatabaseDeletion:
            dismiss(animated: true) { [weak self] in
                guard let self else { return }
                self.present(alertState: self.viewModel.databaseDeletionConfirmationAlert)
            }
        case .confirmDatabaseDeletion:
            sessionManager?.removeDatabaseFromDisk()
        case .cancelDatabaseDeletion:
            showAlert()
        case .learnMoreCertificate:
            UIApplication.shared.open(WireURLs.shared.endToEndIdentityInfo)
        case .getCertificate:
            Task { [weak self] in
                await self?.enrollCertificateAction()
            }
        }
    }

}

private extension BlockerViewModel.ActionStyle {

    var uiAlertActionStyle: UIAlertAction.Style {
        switch self {
        case .default:
            .default
        case .cancel:
            .cancel
        case .destructive:
            .destructive
        }
    }
}

// MARK: - Application state observing

extension BlockerViewController: ApplicationStateObserving {
    func addObserverToken(_ token: NSObjectProtocol) {
        observerTokens.append(token)
    }

    func applicationDidBecomeActive() {
        showAlert()
    }
}

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
            let appDelegate = UIApplication.shared.delegate as? AppDelegate,
            let rootViewController = appDelegate.mainWindow?.rootViewController
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
        successEnrollmentViewController.presentOverAll()
    }

}

// MARK: - Account management

extension BlockerViewController {

    private var switchAccountAction: (() -> Void)? {
        guard
            let accountManager = sessionManager?.accountManager,
            accountManager.numberOfAccounts > 1 else {
            return nil
        }

        return { [weak self] in
            self?.presentAccountSwitcher()
        }
    }

    private func presentAccountSwitcher() {
        guard let accountManager = sessionManager?.accountManager else {
            return
        }

        let otherAccounts = accountManager.sortedAccounts()
            .filter {
                !$0.isEqual(accountManager.selectedAccount)
            }
            .map { account in
                account.toUIModel(action: { [weak self] in
                    self?.handleSwitch(to: account)
                })
            }

        let accountSwitcher = AccountSwitcherHostingController(
            otherAccounts: otherAccounts,
            options: []
        )

        accountSwitcher.view.backgroundColor = .systemBackground

        if let sheet = accountSwitcher.sheetPresentationController {
            sheet.detents = [
                .custom(resolver: { context in
                    context.maximumDetentValue * 0.3
                })
            ]
            sheet.prefersGrabberVisible = false
            sheet.preferredCornerRadius = 24
        }

        // Present swipe to dismiss.
        accountSwitcher.isModalInPresentation = true
        present(accountSwitcher, animated: true)
    }

    private func handleSwitch(to account: Account) {
        sessionManager?.switchTo(account: account)
    }

    private func handleLogout() {
        guard
            let sessionManager,
            let account = sessionManager.currentAccount
        else {
            return
        }

        // TODO: [WPB-18071] allow user to choose whether to delete data
        sessionManager.delete(
            account: account,
            eraseData: true
        )
    }

}
