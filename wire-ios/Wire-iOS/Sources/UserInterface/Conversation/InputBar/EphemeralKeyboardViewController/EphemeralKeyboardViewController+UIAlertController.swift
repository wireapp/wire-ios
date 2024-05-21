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

    enum AlertError: Error {
        case userRejected
    }

    /// We call this method when user decides to add a custom timeout for their messages
    static func requestCustomTimeInterval(over controller: UIViewController,
                                          with completion: @escaping (Result<TimeInterval, Error>) -> Void) {

        let alertController = UIAlertController(title: "Custom timer", message: nil, preferredStyle: .alert)
        alertController.addTextField { (textField: UITextField) in
            textField.keyboardType = .decimalPad
            textField.placeholder = "Time interval in seconds"
        }

        let confirmAction = UIAlertAction(title: L10n.Localizable.General.ok, style: .default) { [weak alertController] _ in
            guard let input = alertController?.textFields?.first,
                  let inputText = input.text,
                  let selectedTimeInterval = TimeInterval(inputText) else {
                return
            }

            completion(.success(selectedTimeInterval))
        }

        alertController.addAction(confirmAction)

        let cancelAction = UIAlertAction.cancel {
            completion(.failure(AlertError.userRejected))
        }

        alertController.addAction(cancelAction)

        controller.present(alertController, animated: true) { [weak alertController] in
            guard let input = alertController?.textFields?.first else {
                return
            }

            input.becomeFirstResponder()
        }
    }
}
