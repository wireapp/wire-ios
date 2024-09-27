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
import WireDataModel

extension UIAlertController {
    static func availabilityExplanation(_ availability: Availability) -> UIAlertController {
        typealias AvailabilityReminderLocale = L10n.Localizable.Availability.Reminder
        let title: String
        let message: String

        switch availability {
        case .none:
            title = AvailabilityReminderLocale.None.title
            message = AvailabilityReminderLocale.None.message

        case .available:
            title = AvailabilityReminderLocale.Available.title
            message = AvailabilityReminderLocale.Available.message

        case .busy:
            title = AvailabilityReminderLocale.Busy.title
            message = AvailabilityReminderLocale.Busy.message

        case .away:
            title = AvailabilityReminderLocale.Away.title
            message = AvailabilityReminderLocale.Away.message
        }

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        alert.addAction(UIAlertAction(
            title: AvailabilityReminderLocale.Action.dontRemindMe,
            style: .default,
            handler: { _ in
                Settings.shared.dontRemindUserWhenChanging(availability)
            }
        ))

        alert.addAction(UIAlertAction(title: AvailabilityReminderLocale.Action.ok, style: .default, handler: { _ in }))

        return alert
    }

    static func availabilityPicker(_ handler: @escaping (_ availability: Availability) -> Void) -> UIAlertController {
        typealias AvailabilityMessageLocale = L10n.Localizable.Availability.Message

        let alert = UIAlertController(
            title: AvailabilityMessageLocale.setStatus,
            message: nil,
            preferredStyle: .actionSheet
        )

        for availability in Availability.allCases {
            alert.addAction(UIAlertAction(title: availability.localizedName, style: .default, handler: { _ in
                handler(availability)
            }))
        }

        alert.popoverPresentationController?.permittedArrowDirections = [.up, .down]
        alert.addAction(UIAlertAction(title: AvailabilityMessageLocale.cancel, style: .cancel, handler: nil))

        return alert
    }
}
