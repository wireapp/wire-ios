//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

import Combine
import Foundation
import UIKit
import WireConversationUI
import WireDataModel
import WireDesign
import WireFoundation
import WireSyncEngine
import WireSystem
import WireReusableUIComponents

protocol NewCellDescription {}
extension NewTextCellDescription: NewCellDescription {}
extension BurstTimestampSenderMessageCellDescription: NewCellDescription {}

final class NewTextCellDescription: ConversationMessageCellDescription {

    typealias View = NewTextCell

    @MainActor lazy var conversationCellModel: ConversationCellModel? = .text(textMessageViewModel)
    
    @MainActor var textMessageViewModel: TextMessageViewModel

    var supportsActions: Bool = true

    private var cancellables: Set<AnyCancellable> = []

    var configuration: View.Configuration {
        .init(text: "", author: "", accentColor: .red)
    }

    weak var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    var topMargin = CGFloat()
    var bottomMargin = CGFloat()

    let containsHighlightableContent = false

    let accessibilityIdentifier: String? = nil
    let accessibilityLabel: String? = nil

    init(textMessageViewModel: TextMessageViewModel) {
        self.textMessageViewModel = textMessageViewModel
        textMessageViewModel.onLinkTapped = { [weak self] url in
            if url.isMention {
                if let message = self?.message,
                   let mention = message.textMessageData?.mentions
                    .toUIModels().first(where: { $0.location == url.mentionLocation }) {
                    return self?.openMention(mention) ?? false
                } else {
                    return false
                }
            }

            // Open the URL
            return url.open()
        }
    }

    func openMention(_ mention: MentionModel) -> Bool {
        guard let mention = mention.object as? Mention else { return true }
        delegate?.conversationMessageWantsToOpenUserDetails(
            UIView(), //TODO: self,
            user: mention.user,
            sourceView: UIView(), // TODO: messageTextView,
            frame: .zero // TODO: selectionRect
        )
        return true
    }

    func textViewDidLongPress(_ textView: LinkInteractionTextView) {
        if !UIMenuController.shared.isMenuVisible {
            if !Settings.isClipboardEnabled {
                menuPresenter?.showSecuredMenu()
            } else {
                menuPresenter?.showMenu()
            }
        }
    }
    
    var menuPresenter: ConversationMessageCellMenuPresenter? {
        ConversationMessageCellMenuPresenter(
            contentView: NewTextCell(), // TODO: self,
            actionController: actionController,
            conversationMessageCellDelegate: delegate
        )
    }
}

final class NewTextCell: UIView, ConversationMessageCell {

    struct Configuration: Equatable {
        let text: String
        let author: String
        let accentColor: UIColor
    }

    weak var delegate: ConversationMessageCellDelegate?
    weak var message: ZMConversationMessage?
    weak var actionController: ConversationMessageActionController?

    var isSelected: Bool = false

    func configure(with object: Configuration, animated: Bool) {}

}
