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

import avs
import Foundation
import WireReusableUIComponents
import WireSyncEngine

final class SettingsSignOutCellDescriptor: SettingsExternalScreenCellDescriptor {

    var requestPasswordController: RequestPasswordController?

    private lazy var activityIndicator = {
        let topMostViewController = UIApplication.shared.topmostViewController(onlyFullScreen: false)!
        return BlockingActivityIndicator(view: topMostViewController.view)
    }()

    init() {
        super.init(
            title: L10n.Localizable.Self.signOut,
            isDestructive: true,
            presentationStyle: .modal,
            identifier: nil,
            presentationAction: { return nil },
            previewGenerator: nil,
            icon: nil,
            accessoryViewMode: .default,
            copiableText: nil,
            settingsTopLevelContent: nil
        )
    }

    private func logout(password: String? = nil) {
        guard let selfUser = ZMUser.selfUser() else { return }

        if selfUser.usesCompanyLogin || password != nil {
            Task { @MainActor in activityIndicator.start() }
            let topMostViewController = UIApplication.shared.topmostViewController(onlyFullScreen: false)
            AVSMediaManager.sharedInstance()?.stop(sound: .ringingFromThemInCallSound)
            AVSMediaManager.sharedInstance()?.stop(sound: .ringingFromThemSound)
            ZMUserSession.shared()?.logout(credentials: UserEmailCredentials(email: "", password: password ?? "")) { [weak topMostViewController] result in
                Task { @MainActor in self.activityIndicator.stop() }
                TrackingManager.shared.disableAnalyticsSharing = false
                if case .failure(let error) = result {
                    topMostViewController?.showAlert(for: error)
                }
            }
        } else {
            guard let account = SessionManager.shared?.accountManager.selectedAccount else { return }
            SessionManager.shared?.delete(account: account)
        }
    }

    override func generateViewController() -> UIViewController? {
        guard let selfUser = ZMUser.selfUser() else { return nil }

        var viewController: UIViewController?

        if selfUser.emailAddress == nil || selfUser.usesCompanyLogin {
            let alert = UIAlertController(title: L10n.Localizable.Self.Settings.AccountDetails.LogOut.Alert.title,
                                          message: L10n.Localizable.Self.Settings.AccountDetails.LogOut.Alert.message,
                                          preferredStyle: .alert)
            let actionCancel = UIAlertAction(title: L10n.Localizable.General.cancel, style: .cancel, handler: nil)
            let actionLogout = UIAlertAction(title: L10n.Localizable.General.ok, style: .destructive, handler: { [weak self] _ in
                self?.logout()
            })
            alert.addAction(actionCancel)
            alert.addAction(actionLogout)

            viewController = alert
        } else {
            requestPasswordController = RequestPasswordController(context: .logout, callback: { [weak self] password in
                guard let password else { return }

                self?.logout(password: password)
            })

            viewController = requestPasswordController?.alertController
        }

        return viewController
    }

}
