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

import UIKit
import WireSyncEngine

// MARK: - AppLockModule.Router

extension AppLockModule {
    final class Router: RouterInterface {
        // MARK: - Properties

        weak var view: View!
        let userSession: UserSession

        init(userSession: UserSession) {
            self.userSession = userSession
        }
    }
}

// MARK: - AppLockModule.Router + AppLockRouterPresenterInterface

extension AppLockModule.Router: AppLockRouterPresenterInterface {
    func performAction(_ action: AppLockModule.Action) {
        switch action {
        case let .createPasscode(shouldInform):
            presentCreatePasscodeModule(shouldInform: shouldInform)

        case .inputPasscode:
            presentInputPasscodeModule()

        case .informUserOfConfigChange:
            presentWarningModule()

        case .openDeviceSettings:
            presentDeviceSettings()
        }
    }

    private func presentCreatePasscodeModule(shouldInform: Bool) {
        let passcodeSetupViewController = PasscodeSetupViewController.createKeyboardAvoidingFullScreenView(
            context: shouldInform ? .forcedForTeam : .createPasscode,
            delegate: view
        )

        view.present(passcodeSetupViewController, animated: true)
    }

    private func presentInputPasscodeModule() {
        guard let selfUser = ZMUser.selfUser() else {
            assertionFailure("ZMUser.selfUser() is nil")
            return
        }

        let unlockViewController = UnlockViewController(selfUser: selfUser, userSession: userSession)
        let keyboardAvoidingViewController = KeyboardAvoidingViewController(viewController: unlockViewController)
        let navigationController = keyboardAvoidingViewController
            .wrapInNavigationController(navigationBarClass: TransparentNavigationBar.self)
        navigationController.modalPresentationStyle = .fullScreen
        unlockViewController.delegate = view
        view.present(navigationController, animated: false)
    }

    private func presentWarningModule() {
        let warningViewController = AppLockChangeWarningViewController(isAppLockActive: true, userSession: userSession)
        warningViewController.modalPresentationStyle = .fullScreen
        warningViewController.delegate = view
        view.present(warningViewController, animated: false)
    }

    private func presentDeviceSettings() {
        UIApplication.shared.openSettings()
    }
}
