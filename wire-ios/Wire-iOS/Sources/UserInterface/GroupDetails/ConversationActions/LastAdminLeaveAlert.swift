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
import WireLocators

enum LastAdminLeaveAlert {

    static func promoteOrDelete(
        groupName: String,
        onPromote: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) -> UIAlertController {
        let alert = UIAlertController(
            title: L10n.Localizable.LastAdminLeave.title(groupName),
            message: L10n.Localizable.LastAdminLeave.promoteOrDeleteMessage,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(
            title: L10n.Localizable.LastAdminLeave.promoteNewAdmin,
            style: .default,
            accessibilityIdentifier: Locators.LastAdminLeaveAlert.promoteNewAdmin.rawValue,
            handler: { _ in onPromote() }
        ))
        alert.addAction(UIAlertAction(
            title: L10n.Localizable.LastAdminLeave.deleteGroup,
            style: .default,
            handler: { _ in onDelete() }
        ))
        alert.addAction(UIAlertAction(title: L10n.Localizable.General.cancel, style: .cancel))
        return alert
    }

    static func deleteOnly(
        groupName: String,
        onDelete: @escaping () -> Void
    ) -> UIAlertController {
        let alert = UIAlertController(
            title: L10n.Localizable.LastAdminLeave.title(groupName),
            message: L10n.Localizable.LastAdminLeave.noEligibleCandidatesMessage,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(
            title: L10n.Localizable.LastAdminLeave.deleteGroup,
            style: .default,
            handler: { _ in onDelete() }
        ))
        alert.addAction(UIAlertAction(title: L10n.Localizable.General.cancel, style: .cancel))
        return alert
    }
}
