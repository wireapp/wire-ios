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

import Foundation
import WireDataModel

enum BlockResult {
    case block(isBlocked: Bool), cancel

    var title: String {
        switch self {
        case .cancel: return L10n.Localizable.Profile.BlockDialog.buttonCancel
        case .block(isBlocked: false): return L10n.Localizable.Profile.blockButtonTitleAction
        case .block(isBlocked: true): return L10n.Localizable.Profile.unblockButtonTitleAction
        }
    }

    private var style: UIAlertAction.Style {
        guard case .cancel = self else { return .destructive }
        return .cancel
    }

    func action(_ handler: @escaping (BlockResult) -> Void) -> UIAlertAction {
        return .init(title: title, style: style) { _ in handler(self) }
    }

    static func title(for user: UserType) -> String? {
        // Do not show the title if the user is already blocked and we want to unblock them.
        if user.isBlocked {
            return nil
        }

        return L10n.Localizable.Profile.BlockDialog.message(user.name ?? "")
    }

    static func all(isBlocked: Bool) -> [BlockResult] {
        return [.block(isBlocked: isBlocked), .cancel]
    }
}

extension ConversationActionController {

    func requestBlockResult(for conversation: ZMConversation, handler: @escaping (BlockResult) -> Void) {
        guard let user = conversation.connectedUser else { return }
        let controller = UIAlertController(title: BlockResult.title(for: user), message: nil, preferredStyle: .actionSheet)
        BlockResult.all(isBlocked: user.isBlocked).map { $0.action(handler) }.forEach(controller.addAction)
        present(controller)
    }

    func handleBlockResult(_ result: BlockResult, for conversation: ZMConversation) {
        guard case .block = result else { return }

        conversation.connectedUser?.block(completion: { [weak self] error in
            if let error = error as? LocalizedError {
                self?.presentError(error)
            } else {
                self?.transitionToListAndEnqueue {}
            }
        })
    }

}
