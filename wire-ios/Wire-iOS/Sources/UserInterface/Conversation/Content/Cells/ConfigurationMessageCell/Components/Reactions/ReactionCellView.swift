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

public struct Reaction {

    let type: MessageReaction
    let count: Int
    let isSelfUserReacting: Bool
    let performReaction: () -> Void

}

enum ReactionType: String {
    case like = "❤️"
    case laugh = "🤣"
    case anger = "😡"

}

final class ReactionsCellView: UIView, ConversationMessageCell {

    typealias Configuration = Void

    let reactionView = ReactionCollectionView()

    var arrayReactions: [Reaction] = []

    var isSelected: Bool  = false

    var message: WireDataModel.ZMConversationMessage?

    weak var delegate: ConversationMessageCellDelegate?

    func configure(
        with object: Configuration,
        animated: Bool
    ) {
        guard let message = message
        else {
            return
        }

        reactionView.reactions = message.usersReaction.compactMap { reaction, usersWhoReacted in
            guard
                let reactionType = MessageReaction.messageReaction(from: reaction),
                !usersWhoReacted.isEmpty
            else {
                return nil
            }

            return Reaction(
                type: reactionType,
                count: usersWhoReacted.count,
                isSelfUserReacting: usersWhoReacted.contains(where: \.isSelfUser),
                performReaction: { [weak self] in
                    guard let `self` = self else { return }
                    self.delegate?.perform(
                        action: .react(reactionType),
                        for: message,
                        view: self
                    )
                }
            )
        }

    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureSubviews()
        configureConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init?(coder aDecoder: NSCoder) is not implemented")
    }

    private func configureSubviews() {
        addSubview(reactionView)
    }

    private func configureConstraints() {
        reactionView.translatesAutoresizingMaskIntoConstraints = false
        self.translatesAutoresizingMaskIntoConstraints = false

        reactionView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        reactionView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 40).isActive = true
        reactionView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        reactionView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
    }

}
