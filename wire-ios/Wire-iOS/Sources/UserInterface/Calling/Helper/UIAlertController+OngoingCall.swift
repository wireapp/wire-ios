//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

    typealias ConversationCallManyParticipants = L10n.Localizable.Conversation.Call.ManyParticipantsConfirmation
    typealias OngoingCallAlert = L10n.Localizable.Call.Alert.Ongoing

    static func ongoingCallJoinCallConfirmation(
        forceAlertModal: Bool = false,
        completion: @escaping (Bool) -> Void
    ) -> UIAlertController {
        return ongoingCallConfirmation(
            title: OngoingCallAlert.alertTitle,
            message: OngoingCallAlert.Join.message,
            buttonTitle: OngoingCallAlert.Join.button,
            forceAlertModal: forceAlertModal,
            completion: completion
        )
    }

    static func confirmGroupCall(
        participants: Int,
        completion: @escaping (Bool) -> Void
    ) -> UIAlertController {
        let controller = UIAlertController(
            title: ConversationCallManyParticipants.title(participants),
            message: nil,
            preferredStyle: .alert
        )

        controller.addAction(.cancel { completion(false) })

        let sendAction = UIAlertAction(
            title: ConversationCallManyParticipants.call,
            style: .default,
            handler: { _ in completion(true) }
        )

        controller.addAction(sendAction)
        return controller
    }

    // MARK: - Helper

    private static func ongoingCallConfirmation(
        title: String,
        message: String,
        buttonTitle: String,
        forceAlertModal: Bool,
        completion: @escaping (Bool) -> Void
    ) -> UIAlertController {

        let defaultStyle: UIAlertController.Style = .alert
        let effectiveStyle = forceAlertModal ? .alert : defaultStyle

        let controller = UIAlertController(
            title: effectiveStyle == .alert ? title : message,
            message: effectiveStyle == .alert ? message : nil,
            preferredStyle: effectiveStyle
        )
        controller.addAction(.init(title: buttonTitle, style: .default) { _ in completion(true) })
        controller.addAction(.cancel { completion(false) })
        return controller
    }

}
