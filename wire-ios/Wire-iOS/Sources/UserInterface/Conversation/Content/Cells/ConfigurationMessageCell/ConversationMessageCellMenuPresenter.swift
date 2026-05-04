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

struct ConversationMessageCellMenuPresenter {

    weak var contentView: (any ConversationMessageCell)?
    weak var actionController: ConversationMessageActionController?
    weak var conversationMessageCellDelegate: ConversationMessageCellDelegate?

    func showMenu() {
        guard
            let contentView,
            let controller = messageActionsMenuController(with: MessageAction.allCases)
        else { return }

        conversationMessageCellDelegate?.conversationMessageCell(contentView, present: controller)
    }

    func showSecuredMenu() {
        let actions = [
            MessageAction.visitLink,
            MessageAction.reply,
            MessageAction.edit,
            MessageAction.openDetails,
            MessageAction.delete,
            MessageAction.cancel
        ]

        guard
            let contentView,
            let controller = messageActionsMenuController(with: actions)
        else { return }

        conversationMessageCellDelegate?.conversationMessageCell(contentView, present: controller)
    }

    func messageActionsMenuController(with actions: [MessageAction]) -> MessageActionsViewController? {
        guard let actionController else { return nil }
        return MessageActionsViewController.controller(withActions: actions, actionController: actionController)
    }

}
