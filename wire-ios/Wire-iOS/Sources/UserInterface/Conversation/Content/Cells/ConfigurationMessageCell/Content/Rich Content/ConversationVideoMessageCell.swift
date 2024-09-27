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
import WireDesign

// MARK: - ConversationVideoMessageCell

final class ConversationVideoMessageCell: RoundedView, ConversationMessageCell {
    struct Configuration {
        let message: ZMConversationMessage
        var isObfuscated: Bool {
            message.isObfuscated
        }
    }

    private var containerView = UIView()
    private let transferView = VideoMessageView(frame: .zero)
    private let obfuscationView = ObfuscationView(icon: .videoMessage)
    private let restrictionView = VideoMessageRestrictionView()

    weak var delegate: ConversationMessageCellDelegate?
    weak var message: ZMConversationMessage?

    var isSelected = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureSubview()
        configureConstraints()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureSubview() {
        shape = .rounded(radius: 12)
        backgroundColor = SemanticColors.View.backgroundCollectionCell
        containerView.layer.cornerRadius = 12
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = SemanticColors.View.borderCollectionCell.cgColor
        clipsToBounds = true

        transferView.delegate = self
        setup(transferView)

        addSubview(containerView)
    }

    private func configureConstraints() {
        containerView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // containerView
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    func configure(with object: Configuration, animated: Bool) {
        if object.isObfuscated {
            setup(obfuscationView)
        } else if !object.message.canBeShared {
            setup(restrictionView, heightMultiplier: 9 / 16)
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
            view.heightAnchor.constraint(equalToConstant: 160),
            view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            view.topAnchor.constraint(equalTo: containerView.topAnchor),
            view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])
    }

    private func setup(_ view: UIView, heightMultiplier: CGFloat) {
        containerView.removeSubviews()
        containerView.addSubview(view)

        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.heightAnchor.constraint(equalTo: widthAnchor, multiplier: heightMultiplier),
            view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            view.topAnchor.constraint(equalTo: containerView.topAnchor),
            view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])
    }

    override var tintColor: UIColor! {
        didSet {
            transferView.tintColor = tintColor
        }
    }

    var selectionRect: CGRect {
        transferView.bounds
    }
}

// MARK: TransferViewDelegate

extension ConversationVideoMessageCell: TransferViewDelegate {
    func transferView(_ view: TransferView, didSelect action: MessageAction) {
        guard let message else { return }

        delegate?.perform(action: action, for: message, view: self)
    }
}

// MARK: - ConversationVideoMessageCellDescription

final class ConversationVideoMessageCellDescription: ConversationMessageCellDescription {
    typealias View = ConversationVideoMessageCell
    let configuration: View.Configuration

    var topMargin: Float = 8
    var showEphemeralTimer = false

    let isFullWidth = false
    let supportsActions = true
    let containsHighlightableContent = true

    weak var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    var accessibilityIdentifier: String? {
        configuration.isObfuscated ? "ObfuscatedVideoCell" : "VideoCell"
    }

    let accessibilityLabel: String?

    init(message: ZMConversationMessage) {
        self.configuration = View.Configuration(message: message)
        self.accessibilityLabel = L10n.Accessibility.ConversationSearch.VideoMessage.description
    }
}
