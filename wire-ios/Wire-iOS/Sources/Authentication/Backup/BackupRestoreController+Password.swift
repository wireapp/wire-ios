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

extension BackupRestoreController {
    func requestRestorePassword(completion: @escaping (String?) -> Void) -> UIAlertController {
        let controller = UIAlertController(
            title: L10n.Localizable.Registration.NoHistory.RestoreBackup.Password.title,
            message: nil,
            preferredStyle: .alert
        )

        var token: Any?

        func complete(_ result: String?) {
            token.map(NotificationCenter.default.removeObserver)
            completion(result)
        }

        let okAction = UIAlertAction(title: L10n.Localizable.General.ok, style: .default) { [controller] _ in
            complete(controller.textFields?.first?.text)
        }

        okAction.isEnabled = false

        controller.addTextField { textField in
            textField.isSecureTextEntry = true
            textField.placeholder = L10n.Localizable.Registration.NoHistory.RestoreBackup.Password.placeholder
            token = NotificationCenter.default.addObserver(forName: UITextField.textDidChangeNotification, object: textField, queue: .main) { _ in
                okAction.isEnabled = textField.text?.count ?? 0 >= 0
            }
        }

        controller.addAction(.cancel { complete(nil) })
        controller.addAction(okAction)
        return controller
    }

    func importWrongPasswordError(completion: @escaping (UIAlertAction) -> Void) -> UIAlertController {
        let controller = UIAlertController(
            title: L10n.Localizable.Registration.NoHistory.RestoreBackup.PasswordError.title,
            message: nil,
            preferredStyle: .alert
        )
        controller.addAction(UIAlertAction(
            title: L10n.Localizable.General.ok,
            style: .default,
            handler: completion
        ))

        return controller
    }
}
