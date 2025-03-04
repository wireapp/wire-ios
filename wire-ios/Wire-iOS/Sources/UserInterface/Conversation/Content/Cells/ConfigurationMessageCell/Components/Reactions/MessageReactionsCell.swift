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

// MARK: - MessageReactionsCell

final class MessageReactionsCell: UIView, ConversationMessageCell {

    // MARK: - Properties

    var isSelected = false
    var message: ZMConversationMessage?
    private var reactions = [MessageReaction]()

    weak var delegate: ConversationMessageCellDelegate?

    private lazy var insets = UIEdgeInsets(
        top: 8,
        left: conversationHorizontalMargins.left,
        bottom: 0,
        right: conversationHorizontalMargins.right
    )

    private lazy var collectionView = {
        let collectionView = MessageReactionsCollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        collectionView.backgroundColor = .clear
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        return collectionView
    }()

    private enum SectionID: Hashable {
        case single
    }

    private lazy var dataSource = UICollectionViewDiffableDataSource<SectionID, Emoji.ID>(
        collectionView: collectionView
    ) { [weak self] collectionView, indexPath, emojiID in
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        if let reaction = self?.reactions.first(where: { $0.emojiID == emojiID }) {
            var reactionToggle: MessageReactionToggleControl! = cell.contentView.subviews
                .compactMap { $0 as? MessageReactionToggleControl }.first
            if reactionToggle == nil {
                reactionToggle = MessageReactionToggleControl(reaction: reaction) { [weak self] in
                    guard let self, let message else { return }
                    delegate?.perform(action: .react(reaction.emojiID), for: message, view: self)
                }
                cell.contentView.addSubview(reactionToggle)
                reactionToggle.fitIn(view: cell.contentView)
            }
        }
        return cell
    }

    private lazy var collectionViewLayout = {
        let layout = MessageReactionsCollectionViewFlowLayout()
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
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: - configure Views and constraints

    private func configureSubviews() {
        collectionView.dataSource = dataSource
        addSubview(collectionView)
        collectionView.fitIn(view: self, insets: insets)
    }

    // MARK: - configure method

    func configure(with reactions: [MessageReaction], animated: Bool) {
        self.reactions = reactions

        var snapshot = NSDiffableDataSourceSnapshot<SectionID, Emoji.ID>()
        snapshot.appendSections([.single])
        snapshot.appendItems(reactions.map(\.emojiID))
        dataSource.apply(snapshot, animatingDifferences: animated)
    }
}
