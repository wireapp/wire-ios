//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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
import WireSyncEngine

final class ConversationMessageToolboxCell: UIView, ConversationMessageCell, MessageToolboxViewDelegate {

    struct Configuration: Equatable {
        var message: ZMConversationMessage
        var deliveryState: ZMDeliveryState
        /// A message status is considered redundant if it does not provide additional information over a subsequent
        /// message's status. This basically means that only the last of subsequent messages of the same sender within a
        /// short time frame will show the status view, if the delivery state is the same.
        /// Self-deleting messages still show the status, because it contains a countdown label.
        let isRedundant: Bool

        static func == (
            lhs: ConversationMessageToolboxCell.Configuration,
            rhs: ConversationMessageToolboxCell.Configuration
        ) -> Bool {
            lhs.deliveryState == rhs.deliveryState &&
                lhs.message == rhs.message &&
                lhs.isRedundant == rhs.isRedundant
        }
    }

    weak var delegate: ConversationMessageCellDelegate?
    weak var message: ZMConversationMessage?
    weak var actionController: ConversationMessageActionController?

    let toolboxView = MessageToolboxView()
    var observerToken: Any?
    var isSelected: Bool = false

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
        toolboxView.delegate = self
        addSubview(toolboxView)
    }

    private func configureConstraints() {
        toolboxView.translatesAutoresizingMaskIntoConstraints = false
        toolboxView.fitIn(view: self)
    }

    func willDisplay() {
        toolboxView.startCountdownTimer()
    }

    func didEndDisplaying() {
        toolboxView.stopCountdownTimer()
    }

    func configure(with object: Configuration, animated: Bool) {
        toolboxView.configureForMessage(object.message, animated: animated)
        if object.isRedundant {
            toolboxView.setAllContentHidden()
        }
    }

    func messageToolboxDidRequestOpeningDetails(
        _ messageToolboxView: MessageToolboxView,
        preferredDisplayMode: MessageDetailsDisplayMode
    ) {
        guard let message, let delegate else { return }
        delegate.conversationMessageWantsToOpenMessageDetails(
            self,
            for: message,
            preferredDisplayMode: preferredDisplayMode
        )
    }

    private func perform(action: MessageAction, sender: UIView? = nil) {
        delegate?.perform(action: action, for: message!, view: selectionView ?? sender ?? self)
    }

    func messageToolboxViewDidSelectDelete(_ sender: UIView?) {
        perform(action: .delete, sender: sender)
    }

    func messageToolboxViewDidSelectResend(_ messageToolboxView: MessageToolboxView) {
        perform(action: .resend)
    }

}

final class ConversationMessageToolboxCellDescription: ConversationMessageCellDescription {
    typealias View = ConversationMessageToolboxCell

    var configuration: View.Configuration

    var message: ZMConversationMessage? {
        didSet {
            if let message {
                configuration = View.Configuration(
                    message: message,
                    deliveryState: message.deliveryState,
                    isRedundant: configuration.isRedundant
                )
            }
        }
    }

    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    let containsHighlightableContent: Bool = false
    let shouldAlignMessageContentForBubbles: Bool = true

    let accessibilityIdentifier: String? = "MessageToolbox"
    let accessibilityLabel: String? = nil

    init(message: ZMConversationMessage, isRedundant: Bool) {
        self.message = message
        self.configuration = View.Configuration(
            message: message,
            deliveryState: message.deliveryState,
            isRedundant: isRedundant
        )
    }

}
