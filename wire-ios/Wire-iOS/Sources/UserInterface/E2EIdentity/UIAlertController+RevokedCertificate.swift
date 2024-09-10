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

extension UIAlertController {
    static func revokedCertificateWarning(logOutActionHandler: @escaping () -> Void) -> UIAlertController {
        typealias Alert = L10n.Localizable.RevokedCertificate.Alert

        let alertController = UIAlertController(
            title: Alert.title,
            message: Alert.message,
            preferredStyle: .alert
        )

        let logOutAction = UIAlertAction(
            title: Alert.logOut,
            style: .default,
            handler: { _ in logOutActionHandler() }
        )

        let continueAction = UIAlertAction(title: Alert.continue, style: .cancel)

        alertController.addAction(logOutAction)
        alertController.addAction(continueAction)

        return alertController
    }
}
