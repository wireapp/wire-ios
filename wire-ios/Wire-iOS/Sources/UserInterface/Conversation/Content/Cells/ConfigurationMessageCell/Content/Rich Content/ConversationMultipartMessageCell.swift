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
import UIKit
import WireDataModel
import WireDesign
import WireMessagingDomain
import WireMessagingUI

final class ConversationMultipartMessageCell: UIView, ConversationMessageCell {

    struct Configuration {
        var attachments: [MultipartMessageData.Attachment]
        let factory: WireCellsFactoryProtocol
    }

    private var containerView = UIView()
    weak var delegate: ConversationMessageCellDelegate?
    weak var message: ZMConversationMessage?
    weak var actionController: ConversationMessageActionController?

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
        containerView.backgroundColor = .clear
        containerView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(containerView)
    }

    private func configureConstraints() {
        let margins = conversationHorizontalMargins
        let constraints = [
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: margins.left),
            containerView.trailingAnchor.constraint(
                equalTo: trailingAnchor,
                constant: -margins.right
            )
        ]

        NSLayoutConstraint.activate([
            // containerView
            containerView.topAnchor.constraint(equalTo: topAnchor),
            bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        NSLayoutConstraint.activate(constraints)
    }

    func configure(
        with object: Configuration,
        animated: Bool
    ) {
        let attachments = object.attachments.map {
            WireCellsMessageAttachment(
                nodeID: $0.nodeID,
                contentType: $0.contentType,
                initialName: $0.initialName,
                initialSize: $0.initialSize,
                initialMetadata: nil
            )
        }

        let viewController = object.factory.makeAttachmentsPreviewView(attachments: attachments)
        setupWireCellsAttachmentsView(viewController: viewController)
    }

    private func setupWireCellsAttachmentsView(viewController: UIViewController) {
        let view: UIView = viewController.view
        containerView.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: containerView.topAnchor),
            view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

    }

    override var tintColor: UIColor! {
        didSet {
            containerView.tintColor = tintColor
        }
    }

    var selectionRect: CGRect {
        containerView.bounds
    }

    func prepareForReuse() {
        containerView.removeSubviews()
    }
}

final class ConversationMultipartMessageCellDescription: ConversationMessageCellDescription {
    typealias View = ConversationMultipartMessageCell

    let configuration: View.Configuration

    weak var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    let containsHighlightableContent: Bool = true

    let accessibilityIdentifier: String? = nil
    let accessibilityLabel: String? = nil

    init(
        multipartMessage: MultipartMessageData,
        wireCellsFactory: WireCellsFactoryProtocol
    ) {
        self.configuration = View.Configuration(
            attachments: multipartMessage.attachments,
            factory: wireCellsFactory
        )
    }
}
