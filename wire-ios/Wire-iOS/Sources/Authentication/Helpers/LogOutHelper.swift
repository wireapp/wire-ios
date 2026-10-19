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

import avs
import UIKit
import WireDataModel
import WireSyncEngine

final class LogOutHelper {

    private var requestPasswordController: RequestPasswordController?

    private let showLoading: () -> Void
    private let hideLoading: () -> Void

    init(
        showLoading: @escaping () -> Void,
        hideLoading: @escaping () -> Void
    ) {
        self.showLoading = showLoading
        self.hideLoading = hideLoading
    }

    func makeLogOutViewControllerToPresent(userSession: UserSession) -> UIViewController? {
        let selfUser = ZMUser.selfUser(in: userSession.contextProvider.viewContext)

        var viewController: UIViewController?

        if selfUser.emailAddress == nil || selfUser.usesCompanyLogin {
            let alert = UIAlertController(
                title: L10n.Localizable.Self.Settings.AccountDetails.LogOut.Alert.title,
                message: L10n.Localizable.Self.Settings.AccountDetails.LogOut.Alert.message,
                preferredStyle: .alert
            )
            let actionCancel = UIAlertAction(title: L10n.Localizable.General.cancel, style: .cancel, handler: nil)
            let actionLogout = UIAlertAction(
                title: L10n.Localizable.General.ok,
                style: .destructive,
                handler: { [weak self] _ in
                    self?.logout(userSession: userSession)
                }
            )
            alert.addAction(actionCancel)
            alert.addAction(actionLogout)

            viewController = alert
        } else {
            requestPasswordController = RequestPasswordController(context: .logout, callback: { [weak self] password in
                guard let password else { return }

                self?.logout(userSession: userSession, password: password)
            })

            viewController = requestPasswordController?.alertController
        }

        return viewController
    }

    func logout(userSession: UserSession, password: String? = nil) {
        let selfUser = ZMUser.selfUser(in: userSession.contextProvider.viewContext)

        if selfUser.usesCompanyLogin || password != nil {
            showLoading()
            let topMostViewController = UIApplication.shared.topmostViewController(onlyFullScreen: false)
            AVSMediaManager.sharedInstance()?.stop(sound: .ringingFromThemInCallSound)
            AVSMediaManager.sharedInstance()?.stop(sound: .ringingFromThemSound)
            (userSession as? ZMUserSession)?.logout(credentials: UserEmailCredentials(
                email: "",
                password: password ?? ""
            )) { [weak topMostViewController, weak self] result in
                self?.hideLoading()
                switch result {
                case let .failure(error):
                    topMostViewController?.showAlert(for: error)
                case .success:
                    self?.tearDownDirectUploads()
                }
            }
        } else {
            SessionManager.shared?.delete(account: userSession.contextProvider.account)
            tearDownDirectUploads()
        }
    }
    
    private func tearDownDirectUploads() {
        Task {
            let wireMessagingFactory = ZClientViewController.shared?.wireMessagingFactory
            await wireMessagingFactory?.tearDownDirectUploads()
        }
    }

}
