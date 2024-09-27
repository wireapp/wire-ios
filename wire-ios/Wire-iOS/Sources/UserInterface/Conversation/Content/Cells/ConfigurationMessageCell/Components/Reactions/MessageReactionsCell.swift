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

// MARK: - MessageReactionMetadata

struct MessageReactionMetadata: Equatable {
    let emoji: Emoji.ID
    let count: UInt
    let isSelfUserReacting: Bool

    static func == (lhs: MessageReactionMetadata, rhs: MessageReactionMetadata) -> Bool {
        lhs.emoji == rhs.emoji && lhs.count == rhs.count && lhs.isSelfUserReacting == rhs.isSelfUserReacting
    }
}

// MARK: - MessageReactionsCell

final class MessageReactionsCell: UIView, ConversationMessageCell {
    // MARK: - Properties

    var isSelected = false
    var message: ZMConversationMessage?

    weak var delegate: ConversationMessageCellDelegate?

    private let reactionsView = GridLayoutView()

    private lazy var insets = UIEdgeInsets(
        top: 8,
        left: conversationHorizontalMargins.left,
        bottom: 0,
        right: conversationHorizontalMargins.right
    )

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
        reactionsView.fitIn(view: self, insets: insets)
    }

    // MARK: - configure method

    func configure(
        with reactions: [MessageReactionMetadata],
        animated: Bool
    ) {
        let reactionToggles = reactions.map { reaction in
            ReactionToggle(
                emoji: reaction.emoji,
                count: reaction.count,
                isToggled: reaction.isSelfUserReacting
            ) { [weak self] in
                guard
                    let self,
                    let message
                else {
                    return
                }

                delegate?.perform(
                    action: .react(reaction.emoji),
                    for: message,
                    view: self
                )
            }
        }

        reactionsView.configure(views: reactionToggles)
    }

    func prepareForReuse() {
        reactionsView.prepareForReuse()
    }

    override func systemLayoutSizeFitting(
        _ targetSize: CGSize,
        withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority,
        verticalFittingPriority: UILayoutPriority
    ) -> CGSize {
        let insetsWidth = insets.left + insets.right
        reactionsView.widthForCalculations = targetSize.width - insetsWidth
        reactionsView.setNeedsLayout()
        reactionsView.layoutIfNeeded()
        return super.systemLayoutSizeFitting(
            CGSize(width: targetSize.width - insetsWidth, height: UIView.noIntrinsicMetric),
            withHorizontalFittingPriority: horizontalFittingPriority,
            verticalFittingPriority: verticalFittingPriority
        )
    }
}
