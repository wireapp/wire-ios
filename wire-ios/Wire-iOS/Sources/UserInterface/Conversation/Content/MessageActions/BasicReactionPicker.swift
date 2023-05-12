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
import WireDataModel

protocol ReactionPickerDelegate: AnyObject {
    func didPickReaction(reaction: MessageReaction)
}

class BasicReactionPicker: UIView {
    private let horizontalStackView = UIStackView(axis: .horizontal)
    private var buttons: [UIButton] = []
    weak var delegate: ReactionPickerDelegate?

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init() {
        super.init(frame: .zero)
        setupViews()
    }

}

private extension BasicReactionPicker {

    func setupViews() {
        horizontalStackView.alignment = .center
        horizontalStackView.distribution = .equalSpacing
        horizontalStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(horizontalStackView)
        NSLayoutConstraint.activate(
            horizontalStackView.fitInConstraints(view: self,
                                                 insets: UIEdgeInsets(top: 16.0, left: 16.0, bottom: 16.0, right: 16.0))
        )
        addButtons()
    }

    func addButtons() {
        ["👍", "🙂", "❤️", "☹️", "👎", "🫥"].forEach { emoji in
            let button = UIButton()
            button.setTitle(emoji, for: .normal)
            button.addTarget(self, action: #selector(didTapEmoji(sender:)), for: .touchUpInside)
            horizontalStackView.addArrangedSubview(button)

        }

    }

    @objc func didTapEmoji(sender: UIButton) {
        guard let reaction = MessageReaction.messageReaction(from: sender.titleLabel?.text ?? "") else { return }
        delegate?.didPickReaction(reaction: reaction)
    }
}
