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

import SwiftUI
import WireDataModel

final class MessageReactionsCell: UIView, ConversationMessageCell, UICollectionViewDelegate {

    // MARK: - Properties

    var isSelected = false
    var message: ZMConversationMessage?

    private var reactions = [MessageReaction]()
    private let collectionView = MessageReactionsCollectionView()

    weak var delegate: ConversationMessageCellDelegate?

    private lazy var dataSource = MessageReactionsDiffableDataSource(
        collectionView: collectionView
    ) { [weak self] collectionView, indexPath, _ in

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        if let reaction = self?.reactions[indexPath.item] {
            cell.contentConfiguration = UIHostingConfiguration {
                MessageReactionView(reaction: reaction)
            }
            .margins(.all, 0)
            .margins(.bottom, 1) // the border of the cell would be clipped otherwise
        }
        return cell
    }

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
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    private func configureSubviews() {

        collectionView.backgroundColor = .clear
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.dataSource = dataSource
        collectionView.delegate = self

        addSubview(collectionView)
        collectionView.fitIn(view: self, insets: insets)

    }

    func configure(with reactions: [MessageReaction], animated: Bool) {
        self.reactions = reactions
        updateCollectionView()
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let message else { return }

        reactions[indexPath.item].isSelfUserReacting.toggle()
        updateCollectionView()

        delegate?.perform(action: .react(reactions[indexPath.item].emojiID), for: message, view: self)
    }

    private func updateCollectionView() {
        var snapshot = MessageReactionsDiffableDataSourceSnapshot()
        snapshot.appendSections([.single])
        snapshot.appendItems(reactions.map(\.emojiID))
        dataSource.applySnapshotUsingReloadData(snapshot)
    }
}
