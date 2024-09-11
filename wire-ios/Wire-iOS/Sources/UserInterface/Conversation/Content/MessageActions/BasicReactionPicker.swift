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
import WireCommonComponents
import WireDataModel
import WireDesign
import WireFoundation

protocol ReactionPickerDelegate: AnyObject {
    func didPickReaction(reaction: Emoji)
    func didTapMoreEmojis()
}

final class BasicReactionPicker: UIView {
    private let titleLabel = DynamicFontLabel(fontSpec: .normalRegularFont,
                                              color: SemanticColors.Label.textUserPropertyCellName)
    private let horizontalStackView = UIStackView(axis: .horizontal)
    private let selectedReactions: Set<Emoji.ID>
    private var buttons = [UIButton]()
    weak var delegate: ReactionPickerDelegate?
    private let emojiRepository: EmojiRepositoryInterface

    private let emojis: [Emoji]

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(
        selectedReactions: Set<Emoji.ID>,
        emojiRepository: EmojiRepositoryInterface = EmojiRepository()
    ) {
        self.selectedReactions = selectedReactions
        self.emojiRepository = emojiRepository
        self.emojis = ["👍", "🙂", "❤️", "☹️", "👎"].compactMap(emojiRepository.emoji(for:))
        super.init(frame: .zero)
        setupViews()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(preferredContentSizeChanged(_:)),
                                               name: UIContentSizeCategory.didChangeNotification,
                                               object: nil)
    }

}

private extension BasicReactionPicker {

    func setupViews() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = L10n.Localizable.Content.Message.reactions
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        addSubview(titleLabel)

        horizontalStackView.alignment = .center
        horizontalStackView.distribution = .equalSpacing
        horizontalStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(horizontalStackView)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            horizontalStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8.0),
            horizontalStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            horizontalStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16.0),
            horizontalStackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        addButtons()
    }

    func addButtons() {
        let currentDevice = DeviceWrapper(device: .current)
        var constraints = [NSLayoutConstraint]()
        emojis.forEach { emoji in
            let button = UIButton()
            button.titleLabel?.font = UIFont.systemFont(ofSize: currentDevice.userInterfaceIdiom == .pad ? 24 : 32)
            button.setTitle(emoji.value, for: .normal)
            if selectedReactions.contains(emoji.value) {
                button.layer.cornerRadius = 12.0
                button.layer.masksToBounds = true
                button.backgroundColor = SemanticColors.Button.reactionBackgroundSelected
                button.layer.borderColor = SemanticColors.Button.reactionBorderSelected.cgColor
                button.layer.borderWidth = 1.0
            }
            button.addTarget(self, action: #selector(didTapEmoji(sender:)), for: .touchUpInside)
            horizontalStackView.addArrangedSubview(button)
            button.translatesAutoresizingMaskIntoConstraints = false
            constraints.append(button.heightAnchor.constraint(equalTo: button.widthAnchor))
            buttons.append(button)
        }

        let button = UIButton()
        buttons.append(button)
        let image = UIImage(resource: .addEmojis)
        button.setImage(image, for: .normal)
        button.addTarget(self, action: #selector(didTapMoreEmojis), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        horizontalStackView.addArrangedSubview(button)
        constraints.append(button.heightAnchor.constraint(equalTo: button.widthAnchor))
        NSLayoutConstraint.activate(constraints)
    }

    @objc func didTapMoreEmojis() {
        delegate?.didTapMoreEmojis()
    }

    @objc func didTapEmoji(sender: UIButton) {
        guard
            let value = sender.titleLabel?.text,
            let emoji = emojis.first(where: { $0.value == value })
        else {
            return
        }

        delegate?.didPickReaction(reaction: emoji)
    }

    @objc func preferredContentSizeChanged(_ notification: Notification) {
        titleLabel.font = UIFont.preferredFont(forTextStyle: .body)
        buttons.forEach { $0.titleLabel?.font = UIFont.preferredFont(forTextStyle: .largeTitle) }
        setNeedsLayout()
    }
}
