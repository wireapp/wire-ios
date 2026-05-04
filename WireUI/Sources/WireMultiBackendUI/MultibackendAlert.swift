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

public enum MultibackendAlertMainApp {

    @MainActor
    public static func obsoleteClient(
        updateAction: @escaping () -> Void,
        switchAccountAction: (() -> Void)?,
        logoutAction: @escaping () -> Void
    ) -> UIAlertController {
        let alertController = UIAlertController(
            title: L10n.Localizable.ObsoleteClientAlert.title,
            message: L10n.Localizable.ObsoleteClientAlert.message,
            preferredStyle: .alert
        )
        let updateAlertAction = UIAlertAction(
            title: L10n.Localizable.ObsoleteAlert.Button.update,
            style: .default
        ) { _ in updateAction() }

        alertController.addAction(updateAlertAction)

        alertController.addSwitchAccountAction(switchAccountAction)
        alertController.addLogoutAction(logoutAction)

        return alertController
    }

    @MainActor
    public static func obsoleteServer(
        switchAccountAction: (() -> Void)?,
        logoutAction: @escaping () -> Void
    ) -> UIAlertController {

        let alertController = UIAlertController(
            title: L10n.Localizable.ObsoleteServerAlert.title,
            message: L10n.Localizable.ObsoleteServerAlert.message,
            preferredStyle: .alert
        )

        alertController.addSwitchAccountAction(switchAccountAction)
        alertController.addLogoutAction(logoutAction)

        return alertController
    }
}

public enum MultibackendAlertInShareExtension {

    @MainActor
    public static func obsoleteClient() -> UIAlertController {
        let alertController = UIAlertController(
            title: L10n.Localizable.ObsoleteClientAlert.title,
            message: L10n.Localizable.ObsoleteClientAlert.message,
            preferredStyle: .alert
        )

        alertController.addOKAction()

        return alertController
    }

    @MainActor
    public static func obsoleteServer() -> UIAlertController {
        let alertController = UIAlertController(
            title: L10n.Localizable.ObsoleteServerAlert.title,
            message: L10n.Localizable.ObsoleteServerAlert.message,
            preferredStyle: .alert
        )

        alertController.addOKAction()

        return alertController
    }
}

public extension UIAlertController {

    func addLogoutAction(_ action: @escaping () -> Void) {
        addAction(UIAlertAction(
            title: L10n.Localizable.ObsoleteAlert.Button.logout,
            style: .default
        ) { _ in action() })
    }

    func addSwitchAccountAction(_ action: (() -> Void)?) {
        if let action {
            addAction(UIAlertAction(
                title: L10n.Localizable.ObsoleteAlert.Button.switchAccounts,
                style: .default
            ) { _ in action() })
        }
    }

    func addOKAction() {
        addAction(UIAlertAction(
            title: L10n.Localizable.ObsoleteAlert.Button.ok,
            style: .default
        ))
    }
}
