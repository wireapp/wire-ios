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

import Foundation
import WireDataModel
import WireSyncEngine

// MARK: - NotificationResult

enum NotificationResult: CaseIterable {
    case everything, mentionsAndReplies, nothing, cancel

    static var title: String {
        L10n.Localizable.Meta.Menu.ConfigureNotification.dialogMessage
    }

    var mutedMessageTypes: MutedMessageTypes? {
        switch self {
        case .everything:
            MutedMessageTypes.none
        case .mentionsAndReplies:
            .regular
        case .nothing:
            .all
        case .cancel:
            nil
        }
    }

    var title: String {
        switch self {
        case .everything: L10n.Localizable.Meta.Menu.ConfigureNotification.buttonEverything
        case .mentionsAndReplies: L10n.Localizable.Meta.Menu.ConfigureNotification.buttonMentionsAndReplies
        case .nothing: L10n.Localizable.Meta.Menu.ConfigureNotification.buttonNothing
        case .cancel: L10n.Localizable.Meta.Menu.ConfigureNotification.buttonCancel
        }
    }

    private var style: UIAlertAction.Style {
        switch self {
        case .cancel: .cancel
        default: .default
        }
    }

    func action(for conversation: ZMConversation, handler: @escaping (NotificationResult) -> Void) -> UIAlertAction {
        let checkmarkText = if let mutedMessageTypes,
                               conversation.mutedMessageTypes == mutedMessageTypes {
            " ✓"
        } else {
            ""
        }

        let title = title + checkmarkText
        return .init(title: title, style: style, handler: { _ in handler(self) })
    }
}

extension ConversationActionController {
    func requestNotificationResult(for conversation: ZMConversation, handler: @escaping (NotificationResult) -> Void) {
        let title = "\(conversation.displayNameWithFallback) • \(NotificationResult.title)"
        let controller = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
        NotificationResult.allCases.map { $0.action(for: conversation, handler: handler) }.forEach(controller.addAction)
        present(controller)
    }

    func handleNotificationResult(_ result: NotificationResult, for conversation: ZMConversation) {
        if let mutedMessageTypes = result.mutedMessageTypes {
            userSession.perform {
                conversation.mutedMessageTypes = mutedMessageTypes
            }
        }
    }
}
