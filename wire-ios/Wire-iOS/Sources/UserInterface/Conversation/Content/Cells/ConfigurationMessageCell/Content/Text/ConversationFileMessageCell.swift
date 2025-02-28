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
import WireDesign

final class ConversationFileMessageCell: UIView, ConversationMessageCell {

    struct Configuration {
        let message: ZMConversationMessage
        var isObfuscated: Bool {
            message.isObfuscated
        }
    }

    private var containerView = RoundedView()
    private let fileTransferView = FileTransferView(frame: .zero)
    private let obfuscationView = ObfuscationView(icon: .paperclip)
    private let restrictionView = FileMessageRestrictionView()

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
        containerView.shape = .rounded(radius: 12)
        containerView.backgroundColor = SemanticColors.View.backgroundCollectionCell
        containerView.layer.cornerRadius = 12
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = SemanticColors.View.borderCollectionCell.cgColor
        clipsToBounds = true

        fileTransferView.delegate = self
        setup(fileTransferView)

        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)
    }

    private func configureConstraints() {
        let margins = conversationHorizontalMargins

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 56),

            containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: margins.left),
            containerView.topAnchor.constraint(equalTo: topAnchor),
            trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: margins.right),
            bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }

    func configure(with object: Configuration, animated: Bool) {
        if object.isObfuscated {
            setup(obfuscationView)
        } else if !object.message.canBeShared {
            setup(restrictionView)
            restrictionView.configure(for: object.message)
        } else {
            fileTransferView.configure(for: object.message, isInitial: false)
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
            fileTransferView.tintColor = tintColor
        }
    }

    var selectionRect: CGRect {
        fileTransferView.bounds
    }

}

extension ConversationFileMessageCell: TransferViewDelegate {
    func transferView(_ view: TransferView, didSelect action: MessageAction) {
        guard let message else { return }

        delegate?.perform(action: action, for: message, view: self)
    }
}

final class ConversationFileMessageCellDescription: ConversationMessageCellDescription {
    typealias View = ConversationFileMessageCell
    let configuration: View.Configuration

    var topMargin: CGFloat = 8
    var showEphemeralTimer: Bool = false

    let supportsActions: Bool = true
    let containsHighlightableContent: Bool = true

    weak var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    var accessibilityIdentifier: String? {
        configuration.isObfuscated ? "ObfuscatedFileCell" : "FileCell"
    }

    let accessibilityLabel: String? = nil

    init(message: ZMConversationMessage) {
        self.configuration = View.Configuration(message: message)
    }

}
