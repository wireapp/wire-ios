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

import UIKit
import WireDataModel

// MARK: - Reaction

struct MessageReactionMetadata: Equatable {
    let emoji: Emoji.ID
    let count: UInt
    let isSelfUserReacting: Bool
}

// MARK: - MessageReactionsCell

final class MessageReactionsCell: UIView, ConversationMessageCell {

    // MARK: - Properties

    var isSelected = false
    var message: ZMConversationMessage?

    weak var delegate: ConversationMessageCellDelegate?

    private lazy var insets = UIEdgeInsets(
        top: 8,
        left: conversationHorizontalMargins.left,
        bottom: 0,
        right: conversationHorizontalMargins.right
    )

    private lazy var collectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        // collectionView.backgroundColor = .white
        collectionView.dataSource = self
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        return collectionView
    }()

    private lazy var dataSource = UICollectionViewDiffableDataSource(
        collectionView: collectionView
    ) { collectionView, indexPath, itemID in
        fatalError()
    }

    private lazy var collectionViewLayout = {
        let layout = LeftAlignedCollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        return layout
    }()

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
        addSubview(collectionView)
        collectionView.fitIn(view: self, insets: insets)
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

        //reactionsView.configure(views: reactionToggles)
    }
}

// MARK: -

private final class LeftAlignedCollectionViewFlowLayout: UICollectionViewFlowLayout {

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        // Get the default attributes from the superclass
        guard let attributes = super.layoutAttributesForElements(in: rect) else { return nil }
        // Create a copy to avoid modifying read-only attributes
        let attributesCopy = attributes.map { $0.copy() as! UICollectionViewLayoutAttributes }

        var leftMargin = sectionInset.left
        var maxY: CGFloat = -1.0

        for attribute in attributesCopy {
            if attribute.representedElementCategory == .cell {
                // If this cell is on a new line, reset the left margin
                if attribute.frame.origin.y >= maxY {
                    leftMargin = sectionInset.left
                }
                // Set the x position of the cell to the left margin
                attribute.frame.origin.x = leftMargin
                // Update the left margin for the next cell
                leftMargin += attribute.frame.width + minimumInteritemSpacing
                // Update the maximum y value for this row
                maxY = max(attribute.frame.maxY, maxY)
            }
        }
        return attributesCopy
    }
}
