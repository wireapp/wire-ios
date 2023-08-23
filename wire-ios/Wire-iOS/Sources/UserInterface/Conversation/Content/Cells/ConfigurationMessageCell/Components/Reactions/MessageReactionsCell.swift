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

import Foundation
import UIKit
import WireDataModel

// MARK: - Reaction

public struct MessageReactionMetadata: Equatable {

    let emoji: Emoji
    let count: UInt
    let isSelfUserReacting: Bool
    var performReaction: (() -> Void)?

    public static func == (lhs: MessageReactionMetadata, rhs: MessageReactionMetadata) -> Bool {
        return lhs.emoji == rhs.emoji && lhs.count == rhs.count && lhs.isSelfUserReacting == rhs.isSelfUserReacting
    }

}

// MARK: - MessageReactionsCell

final class MessageReactionsCell: UIView, ConversationMessageCell {

    struct Configuration: Equatable {

        let reactions: [MessageReactionMetadata]

    }

    // MARK: - Properties

    var isSelected = false
    var message: ZMConversationMessage?

    weak var delegate: ConversationMessageCellDelegate?

    private let reactionsView = GridLayoutView()

    // MARK: - Life cycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureSubviews()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init?(coder aDecoder: NSCoder) is not implemented")
    }

    // MARK: - configure Views and constraints

    private func configureSubviews() {
        addSubview(reactionsView)
        configureConstraints()
    }

    private func configureConstraints() {
        reactionsView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            reactionsView.leadingAnchor.constraint(
                equalTo: leadingAnchor,
                constant: conversationHorizontalMargins.left
            ),
            reactionsView.topAnchor.constraint(
                equalTo: topAnchor,
                constant: 8
            ),
            reactionsView.trailingAnchor.constraint(
                equalTo: trailingAnchor,
                constant: -conversationHorizontalMargins.right
            ),
            reactionsView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    // MARK: - configure method

    func configure(
        with object: Configuration,
        animated: Bool
    ) {
        let reactions = object.reactions.map { reaction in
            return MessageReactionMetadata(
                emoji: reaction.emoji,
                count: reaction.count,
                isSelfUserReacting: reaction.isSelfUserReacting
            ) { [weak self] in
                guard
                    let `self` = self,
                    let message = self.message
                else {
                    return
                }

                self.delegate?.perform(
                    action: .react(reaction.emoji),
                    for: message,
                    view: self
                )
            }
        }.map(ReactionToggle.init)

        reactionsView.configure(views: reactions)
    }

}
