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

//    private var actionController: ConversationMessageActionController
//
//    init(actionController: ConversationMessageActionController) {
//        self.actionController = actionController
//        super.init(title: nil, message: nil, preferredStyle: .actionSheet)
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    func addMessageActions(_ actions: [MessageAction], withActionController actionController: ConversationMessageActionController) {
        actions.forEach { action in
            addAction(action, withActionController: actionController)
        }
        addCancelAction()
    }

    private func addCancelAction() {
        let cancelAction = UIAlertAction(title: L10n.Localizable.General.cancel, style: .cancel)
        addAction(cancelAction)
    }

//    private 

    private func addAction(_ action: MessageAction, withActionController actionController: ConversationMessageActionController) {
        guard let title = action.title,
              let selector = action.selector,
            actionController.canPerformAction(selector)
        else { return }
        let style: UIAlertAction.Style = (action == .delete) ? .destructive : .default
        let newAction = UIAlertAction(title: title, style: style) { [actionController] in
            action.selector(
        }
        if let image = action.icon?.makeImage(size: .small, color: SemanticColors.Icon.foregroundDefaultBlack) {
            newAction.setValue(image, forKey: "image")
        }
        newAction.setValue(CATextLayerAlignmentMode.right, forKey: "titleTextAlignment")
        addAction(newAction)
    }
    


}
