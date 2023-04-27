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

class MessageActionsViewController: UIAlertController {

    var actionController: ConversationMessageActionController?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    func addMessageActions(_ actions: [MessageAction], withActionController actionController: ConversationMessageActionController) {
        self.actionController = actionController
        addReactionsView()
        actions.forEach { action in
            addAction(action, withActionController: actionController)
        }
        addCancelAction()
    }

    private func addCancelAction() {
        let cancelAction = UIAlertAction(title: L10n.Localizable.General.cancel, style: .cancel)
        addAction(cancelAction)
    }

    private func addReactionsView() {
        let reactionPicker = BasicReactionPicker()
        reactionPicker.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(reactionPicker)
        NSLayoutConstraint.activate([
            reactionPicker.heightAnchor.constraint(equalToConstant: 64.0),
            reactionPicker.widthAnchor.constraint(equalTo: view.widthAnchor)
        ])

        let placeholder = UIAlertAction(title: "\n\n\n", style: .default, handler: nil)
        addAction(placeholder)
    }

    private func addAction(_ action: MessageAction, withActionController actionController: ConversationMessageActionController) {
        guard let title = action.title,
              let selector = action.selector,
            actionController.canPerformAction(selector)
        else { return }
        let style: UIAlertAction.Style = (action == .delete) ? .destructive : .default
        let newAction = UIAlertAction(title: title, style: style) { [action, weak actionController] _ in

            actionController?.perform(action: action)
         }
        if let image = action.icon?.makeImage(size: .small, color: SemanticColors.Icon.foregroundDefaultBlack) {
            newAction.setValue(image, forKey: "image")
        }
        newAction.setValue(CATextLayerAlignmentMode.right, forKey: "titleTextAlignment")
        addAction(newAction)
    }

}
