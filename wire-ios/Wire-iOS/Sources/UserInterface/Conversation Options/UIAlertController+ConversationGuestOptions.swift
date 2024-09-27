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
import WireDesign

// MARK: - GuestLinkType

enum GuestLinkType {
    case secure
    case normal
}

private typealias GuestRoom = L10n.Localizable.GuestRoom

extension UIAlertController {
    static func checkYourConnection() -> UIAlertController {
        let controller = UIAlertController(
            title: GuestRoom.Error.Generic.title,
            message: GuestRoom.Error.Generic.message,
            preferredStyle: .alert
        )
        controller.addAction(UIAlertAction(
            title: L10n.Localizable.General.ok,
            style: .default
        ))
        controller.view.tintColor = SemanticColors.Label.textDefault
        return controller
    }

    static func confirmRemovingGuests(
        _ completion: @escaping (Bool) -> Void
    ) -> UIAlertController {
        confirmController(
            title: GuestRoom.RemoveGuests.message,
            confirmTitle: GuestRoom.RemoveGuests.action,
            completion: completion
        )
    }

    static func confirmRevokingLink(_ completion: @escaping (Bool) -> Void) -> UIAlertController {
        confirmController(
            title: GuestRoom.RevokeLink.message,
            confirmTitle: GuestRoom.RevokeLink.action,
            completion: completion
        )
    }

    static func confirmController(
        title: String,
        message: String? = nil,
        confirmAction: UIAlertAction,
        completion: @escaping (Bool) -> Void
    ) -> UIAlertController {
        let controller = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)

        controller.addAction(confirmAction)
        controller.addAction(.cancel { completion(false) })
        controller.view.tintColor = SemanticColors.Label.textDefault
        return controller
    }

    static func confirmController(
        title: String,
        message: String? = nil,
        confirmTitle: String,
        completion: @escaping (Bool) -> Void
    ) -> UIAlertController {
        let confirmAction = UIAlertAction(title: confirmTitle, style: .destructive) { _ in
            completion(true)
        }

        return UIAlertController.confirmController(
            title: title,
            message: message,
            confirmAction: confirmAction,
            completion: completion
        )
    }

    static func guestLinkTypeController(
        completion: @escaping (GuestLinkType) -> Void
    ) -> UIAlertController {
        let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let createGuestLinkWithPasswordAction = UIAlertAction(
            title: GuestRoom.Create.LinkWithPassword.action,
            style: .default
        ) { _ in
            completion(.secure)
        }

        let createGuestLinkWithoutPasswordAction = UIAlertAction(
            title: GuestRoom.Create.LinkWithoutPassword.action,
            style: .default
        ) { _ in
            completion(.normal)
        }

        controller.addAction(createGuestLinkWithPasswordAction)
        controller.addAction(createGuestLinkWithoutPasswordAction)
        controller.addAction(.cancel())

        return controller
    }
}
