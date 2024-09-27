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

// MARK: - ClearContentResult

enum ClearContentResult {
    case delete(leave: Bool), cancel

    // MARK: Internal

    static var title: String {
        L10n.Localizable.Meta.Menu.DeleteContent.dialogMessage
    }

    var title: String {
        switch self {
        case .cancel: L10n.Localizable.General.cancel
        case .delete(leave: true): L10n.Localizable.Meta.Menu.DeleteContent.buttonDeleteAndLeave
        case .delete(leave: false): L10n.Localizable.Meta.Menu.DeleteContent.buttonDelete
        }
    }

    static func options(for conversation: ZMConversation) -> [ClearContentResult] {
        if conversation.conversationType == .oneOnOne || !conversation.isSelfAnActiveMember {
            [.delete(leave: false), .cancel]
        } else {
            [.delete(leave: true), .delete(leave: false), .cancel]
        }
    }

    func action(_ handler: @escaping (ClearContentResult) -> Void) -> UIAlertAction {
        .init(title: title, style: style) { _ in handler(self) }
    }

    // MARK: Private

    private var style: UIAlertAction.Style {
        guard case .cancel = self else { return .destructive }
        return .cancel
    }
}

extension ConversationActionController {
    func requestClearContentResult(for conversation: ZMConversation, handler: @escaping (ClearContentResult) -> Void) {
        let controller = UIAlertController(title: ClearContentResult.title, message: nil, preferredStyle: .actionSheet)
        ClearContentResult.options(for: conversation).map { $0.action(handler) }.forEach(controller.addAction)
        if let sourceView, controller.popoverPresentationController != nil {
            currentContext = .sourceView(sourceView.superview!, sourceView.frame)
        }
        present(controller)
    }

    func handleClearContentResult(_ result: ClearContentResult, for conversation: ZMConversation) {
        guard case let .delete(leave: leave) = result else { return }
        guard let user = SelfUser.provider?.providedSelfUser else {
            assertionFailure("expected available 'user'!")
            return
        }

        transitionToListAndEnqueue {
            conversation.clearMessageHistory()
            if leave {
                conversation.removeOrShowError(participant: user)
            }
        }
    }
}
