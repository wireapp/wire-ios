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
import WireDesign

final class MessageActionsViewController: UIAlertController {
    // We're using custom marker to add space for custom view in UIAlertController. Solution explained in
    // https://stackoverflow.com/a/47925120
    private static let MessageLabelMarker = "__CUSTOM_CONTENT_MARKER__"

    static func controller(
        withActions actions: [MessageAction],
        actionController: ConversationMessageActionController
    ) -> MessageActionsViewController {
        let title = actionController.canPerformAction(action: .react("❤️")) ? MessageLabelMarker : nil
        let controller = MessageActionsViewController(
            title: title,
            message: nil,
            preferredStyle: .actionSheet
        )
        controller.addMessageActions(actions, withActionController: actionController)
        return controller
    }

    private var actionController: ConversationMessageActionController?

    private func addMessageActions(
        _ actions: [MessageAction],
        withActionController actionController: ConversationMessageActionController
    ) {
        self.actionController = actionController
        addReactionsView(withDelegate: self)
        actions.forEach { addAction($0) }
        addCancelAction()
    }

    private func addCancelAction() {
        let cancelAction = UIAlertAction(title: L10n.Localizable.General.cancel, style: .cancel)
        addAction(cancelAction)
    }

    private func addReactionsView(withDelegate delegate: ReactionPickerDelegate) {
        guard let customContentPlaceholder = view
            .findLabel(withText: MessageActionsViewController.MessageLabelMarker),
            let customContainer = customContentPlaceholder.superview else { return }

        let reactionPicker = BasicReactionPicker(selectedReactions: actionController?.message.selfUserReactions() ?? [])

        reactionPicker.delegate = delegate
        reactionPicker.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(reactionPicker)
        customContentPlaceholder.text = ""
        reactionPicker.setContentHuggingPriority(.defaultLow, for: .vertical)
        reactionPicker.setContentCompressionResistancePriority(.required, for: .vertical)

        NSLayoutConstraint.activate([
            reactionPicker.heightAnchor.constraint(greaterThanOrEqualToConstant: 72),
            reactionPicker.widthAnchor.constraint(equalTo: customContainer.widthAnchor),
            reactionPicker.leadingAnchor.constraint(equalTo: customContainer.leadingAnchor),
            reactionPicker.topAnchor.constraint(equalTo: customContainer.topAnchor),
            customContainer.heightAnchor.constraint(equalTo: reactionPicker.heightAnchor),
        ])
    }

    private func addAction(_ action: MessageAction) {
        guard let title = action.title,
              let actionController,
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

extension MessageActionsViewController: ReactionPickerDelegate {
    func didPickReaction(reaction: Emoji) {
        actionController?.perform(action: .react(reaction.value))
    }

    func didTapMoreEmojis() {
        let pickerController = CompleteReactionPickerViewController(
            selectedReactions: actionController?.message
                .selfUserReactions() ?? []
        )
        pickerController.delegate = self
        present(pickerController, animated: true)
    }
}

extension MessageActionsViewController: EmojiPickerViewControllerDelegate {
    func emojiPickerDidSelectEmoji(_ emoji: Emoji) {
        actionController?.perform(action: .react(emoji.value))
        dismiss(animated: true)
    }

    func emojiPickerDeleteTapped() {}
}

extension UIView {
    fileprivate func findLabel(withText text: String) -> UILabel? {
        if let label = self as? UILabel, label.text == text {
            return label
        }
        for subview in subviews {
            if let found = subview.findLabel(withText: text) {
                return found
            }
        }

        return nil
    }
}
