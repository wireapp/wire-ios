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

import Foundation
import UIKit
import WireDataModel

final class ConversationAudioMessageCell: RoundedView, ConversationMessageCell {

    struct Configuration {
        let message: ZMConversationMessage
        var isObfuscated: Bool {
            return message.isObfuscated
        }
    }

    private var containerView = UIView()
    private let transferView = AudioMessageView()
    private let obfuscationView = ObfuscationView(icon: .microphone)
    private let restrictionView = AudioMessageRestrictionView()

    weak var delegate: ConversationMessageCellDelegate?
    weak var message: ZMConversationMessage?

    var isSelected: Bool = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureSubview()
        configureConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureSubview() {
        shape = .rounded(radius: 12)
        backgroundColor = SemanticColors.View.backgroundCollectionCell
        containerView.layer.cornerRadius = 12
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = SemanticColors.View.borderCollectionCell.cgColor
        clipsToBounds = true
        setup(transferView)

        addSubview(containerView)
    }

    private func configureConstraints() {
        containerView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 56),
            // containerView
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    func configure(with object: Configuration, animated: Bool) {
        if object.isObfuscated {
            setup(obfuscationView)
        } else if !object.message.canBeShared {
            setup(restrictionView)
            restrictionView.configure()
        } else {
            transferView.configure(for: object.message, isInitial: false)
        }
    }

    private func setup(_ view: UIView) {
        containerView.removeSubviews()
        containerView.addSubview(view)

        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            view.topAnchor.constraint(equalTo: containerView.topAnchor),
            view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }

    override var tintColor: UIColor! {
        didSet {
            self.transferView.tintColor = self.tintColor
        }
    }

    var selectionView: UIView! {
        return transferView
    }

    var selectionRect: CGRect {
        return transferView.bounds
    }

}

extension ConversationAudioMessageCell: TransferViewDelegate {
    func transferView(_ view: TransferView, didSelect action: MessageAction) {
        guard let message = message else { return }

        delegate?.perform(action: action, for: message, view: self)
    }
}

final class ConversationAudioMessageCellDescription: ConversationMessageCellDescription {
    typealias View = ConversationAudioMessageCell
    let configuration: View.Configuration

    var topMargin: Float = 8
    var showEphemeralTimer: Bool = false

    let isFullWidth: Bool = false
    let supportsActions: Bool = true
    let containsHighlightableContent: Bool = true

    weak var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    var accessibilityIdentifier: String? {
        return configuration.isObfuscated ? "ObfuscatedAudioCell" : "AudioCell"
    }

    let accessibilityLabel: String?

    init(message: ZMConversationMessage) {
        self.configuration = View.Configuration(message: message)
        accessibilityLabel = L10n.Accessibility.ConversationSearch.AudioMessage.description
    }

}
