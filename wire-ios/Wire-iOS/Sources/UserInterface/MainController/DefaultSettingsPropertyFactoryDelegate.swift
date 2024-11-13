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

import WireMainNavigationUI
import WireSyncEngine

final class DefaultSettingsPropertyFactoryDelegate: SettingsPropertyFactoryDelegate, PasscodeSetupViewControllerDelegate {

    var userSession: any UserSession
    var settingsTableViewController: () -> SettingsTableViewController?
    var mainCoordinator: AnyMainCoordinator

    init(
        userSession: any UserSession,
        settingsTableViewController: @escaping () -> SettingsTableViewController?,
        mainCoordinator: AnyMainCoordinator
    ) {
        self.userSession = userSession
        self.settingsTableViewController = settingsTableViewController
        self.mainCoordinator = mainCoordinator
    }

    /// Create or delete custom passcode when appLock option did change
    /// If custom passcode is not enabled, no action is taken
    ///
    /// - Parameters:
    ///   - settingsPropertyFactory: caller of this delegate method
    ///   - newValue: new value of app lock option
    ///   - callback: callback for PasscodeSetupViewController
    func appLockOptionDidChange(
        _ settingsPropertyFactory: SettingsPropertyFactory,
        newValue: Bool,
        callback: @escaping ResultHandler
    ) {
        // There is an additional check for the simulator because there's no way to disable the device passcode on the simulator. We need it for testing.
        guard AuthenticationType.current == .unavailable || (UIDevice.isSimulator && AuthenticationType.current == .passcode) else {
            callback(newValue)
            return
        }

        guard newValue else {
            try? userSession.deleteAppLockPasscode()
            callback(newValue)
            return
        }

        let passcodeSetupViewController = PasscodeSetupViewController(context: .createPasscode, callback: callback)
        passcodeSetupViewController.passcodeSetupViewControllerDelegate = self

        let keyboardAvoidingViewController = KeyboardAvoidingViewController(viewController: passcodeSetupViewController)

        let wrappedViewController = keyboardAvoidingViewController.wrapInNavigationController(navigationBarClass: TransparentNavigationBar.self)

        let closeItem = passcodeSetupViewController.closeItem

        keyboardAvoidingViewController.navigationItem.leftBarButtonItem = closeItem

        wrappedViewController.presentationController?.delegate = passcodeSetupViewController
        wrappedViewController.modalPresentationStyle = .formSheet

        Task {
            await mainCoordinator.presentViewController(wrappedViewController)
        }
    }

    // MARK: - PasscodeSetupViewControllerDelegate

    func passcodeSetupControllerDidFinish() {
        // no-op
    }

    func passcodeSetupControllerWasDismissed() {
        // refresh options applock switch
        settingsTableViewController()?.refreshData()
    }
}
