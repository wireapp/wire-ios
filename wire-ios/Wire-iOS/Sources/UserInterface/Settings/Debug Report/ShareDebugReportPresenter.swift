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
import WireSyncEngine

/// Presents the share debug report flow from the shake gesture.
final class ShareDebugReportPresenter {

    private(set) var isPresenting = false
    private weak var presentedSheet: UIAlertController?

    @MainActor
    func dismiss(completion: @escaping @MainActor () -> Void) {
        guard isPresenting, let sheet = presentedSheet else {
            completion()
            return
        }
        sheet.dismiss(animated: true) { [weak self] in
            self?.isPresenting = false
            self?.presentedSheet = nil
            completion()
        }
    }

    @MainActor
    func present(from topMostViewController: UIViewController?) {
        guard !isPresenting, let viewController = topMostViewController else { return }
        isPresenting = true

        let userSession = SessionManager.shared?.activeUserSession
        let mainCoordinator = ZClientViewController.shared?.mainCoordinator
        let selfUserID = (userSession as? ZMUserSession)?.selfUser.remoteIdentifier

        let viewModel = ShareDebugReportViewModel(
            userSession: userSession,
            mainCoordinator: mainCoordinator,
            selfUserID: selfUserID
        )

        typealias l10n = L10n.Localizable.Self.Settings.ShareDebugReport.ActionSheet
        let actionSheet = UIAlertController(
            title: l10n.title,
            message: l10n.message,
            preferredStyle: .actionSheet
        )

        if viewModel.canShareViaWire {
            actionSheet.addAction(UIAlertAction(title: l10n.shareViaWire, style: .default) { [weak self] _ in
                self?.isPresenting = false
                Task { await viewModel.shareViaWire() }
            })
        }
        if viewModel.canSendEmail {
            actionSheet.addAction(UIAlertAction(title: l10n.sendEmail, style: .default) { [weak self] _ in
                self?.isPresenting = false
                Task { await viewModel.sendEmail() }
            })
        }
        actionSheet.addAction(UIAlertAction(title: l10n.share, style: .default) { [weak self] _ in
            self?.isPresenting = false
            Task { await viewModel.shareViaActivitySheet() }
        })
        actionSheet.addAction(UIAlertAction(title: L10n.Localizable.General.cancel, style: .cancel) { [weak self] _ in
            self?.isPresenting = false
        })

        presentedSheet = actionSheet
        viewController.present(actionSheet, animated: true)
    }
}
