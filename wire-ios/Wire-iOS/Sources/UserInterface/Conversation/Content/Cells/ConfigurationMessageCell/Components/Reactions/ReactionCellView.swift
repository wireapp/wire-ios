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

public struct Reaction: Equatable {
    let reaction: String
    let count: Int
}

final class ReactionsCellView: UIView, ConversationMessageCell {
    let reactionView = ReactionCollectionView()

    struct Configuration: Equatable {
        let color: UIColor
        //let reactions: [Reaction]

    }

    let arrayReactions: [Reaction] = []

    var isSelected: Bool  = false

    var message: WireDataModel.ZMConversationMessage?

    weak var delegate: ConversationMessageCellDelegate?

    func configure(with object: Configuration, animated: Bool) {
        guard let test = message?.usersReaction  else { return }
        let count = test.count

        reactionView.configureData(reactionArray: arrayReactions)

        backgroundColor = object.color
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
        reactionView.fitIn(view: self)
    }

}
