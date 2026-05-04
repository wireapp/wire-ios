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

extension AddBotError {

    typealias PeoplePickerAppsLocale = L10n.Localizable.Peoplepicker.Apps.AddApp

    var localizedTitle: String {
        PeoplePickerAppsLocale.Error.title
    }

    var localizedMessage: String {
        switch self {
        case .tooManyParticipants:
            PeoplePickerAppsLocale.Error.title
        default:
            PeoplePickerAppsLocale.Error.default
        }
    }

    func displayAddBotError(in viewController: UIViewController) {
        let alert = UIAlertController(
            title: localizedTitle,
            message: localizedMessage,
            preferredStyle: .alert
        )
        alert.addAction(.confirm())

        viewController.present(alert, animated: true)
    }
}
