//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

    static func confirmPing(
        participants: Int,
        completion: @escaping (Bool) -> Void
    ) -> UIAlertController {

        let controller = UIAlertController(
            title: L10n.Localizable.Conversation.Ping.ManyParticipantsConfirmation.title(participants),
            message: nil,
            preferredStyle: .alert
        )

        controller.addAction(.cancel { completion(false) })

        let sendAction = UIAlertAction(
            title: L10n.Localizable.Conversation.Ping.Action.title,
            style: .default,
            handler: { _ in completion(true) }
        )

        controller.addAction(sendAction)
        return controller
    }
}
