//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

import Foundation
import UIKit
import WireSyncEngine

extension UIAlertController {

    static func degradedCall(degradedUser: UserType?, callEnded: Bool = false, confirmationBlock: ((_ continueDegradedCall: Bool) -> Void)? = nil) -> UIAlertController {
        let title = callEnded ?
        L10n.Localizable.Call.Degraded.Ended.Alert.title :
        L10n.Localizable.Call.Degraded.Alert.title

        var message: String
        if let user = degradedUser {
            if callEnded {
                message = user.isSelfUser ?
                L10n.Localizable.Call.Degraded.Ended.Alert.Message.`self` :
                L10n.Localizable.Call.Degraded.Ended.Alert.Message.user(user.name ?? "")
            } else {
                message = user.isSelfUser ?
                L10n.Localizable.Call.Degraded.Alert.Message.`self` :
                L10n.Localizable.Call.Degraded.Alert.Message.user(user.name ?? "")
            }
        } else {
            message = callEnded ?
            L10n.Localizable.Call.Degraded.Ended.Alert.Message.unknown :
            L10n.Localizable.Call.Degraded.Alert.Message.unknown
        }

        // Create controller
        let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)

        // Add actions
        if let confirmationBlock = confirmationBlock {
            controller.addAction(UIAlertAction(title: L10n.Localizable.General.cancel, style: .cancel) { _ in
                confirmationBlock(false)
            })

            controller.addAction(UIAlertAction(title: L10n.Localizable.Call.Degraded.Alert.Action.continue, style: .default) { _ in
                confirmationBlock(true)
            })
        } else {
            controller.addAction(UIAlertAction(title: L10n.Localizable.General.ok, style: .default))
        }

        return controller
    }
}
