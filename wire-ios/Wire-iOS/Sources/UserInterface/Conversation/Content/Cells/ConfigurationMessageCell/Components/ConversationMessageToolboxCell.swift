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
import WireSyncEngine

// MARK: - ConversationMessageToolboxCell

final class ConversationMessageToolboxCell: UIView, ConversationMessageCell, MessageToolboxViewDelegate {
    // MARK: Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureSubviews()
        configureConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init?(coder aDecoder: NSCoder) is not implemented")
    }

    // MARK: Internal

    struct Configuration: Equatable {
        let message: ZMConversationMessage
        let deliveryState: ZMDeliveryState

        static func == (
            lhs: ConversationMessageToolboxCell.Configuration,
            rhs: ConversationMessageToolboxCell.Configuration
        ) -> Bool {
            lhs.deliveryState == rhs.deliveryState &&
                lhs.message == rhs.message
        }
    }

    let toolboxView = MessageToolboxView()
    weak var delegate: ConversationMessageCellDelegate?
    weak var message: ZMConversationMessage?

    var observerToken: Any?
    var isSelected = false

    func willDisplay() {
        toolboxView.startCountdownTimer()
    }

    func didEndDisplaying() {
        toolboxView.stopCountdownTimer()
    }

    func configure(with object: Configuration, animated: Bool) {
        toolboxView.configureForMessage(object.message, animated: animated)
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

    func messageToolboxViewDidSelectDelete(_ sender: UIView?) {
        perform(action: .delete, sender: sender)
    }

    func messageToolboxViewDidSelectResend(_: MessageToolboxView) {
        perform(action: .resend)
    }

    // MARK: Private

    private func configureSubviews() {
        toolboxView.delegate = self
        addSubview(toolboxView)
    }

    private func configureConstraints() {
        toolboxView.translatesAutoresizingMaskIntoConstraints = false
        toolboxView.fitIn(view: self)
    }

    private func perform(action: MessageAction, sender: UIView? = nil) {
        delegate?.perform(action: action, for: message!, view: selectionView ?? sender ?? self)
    }
}

// MARK: - ConversationMessageToolboxCellDescription

final class ConversationMessageToolboxCellDescription: ConversationMessageCellDescription {
    // MARK: Lifecycle

    init(message: ZMConversationMessage) {
        self.message = message
        self.configuration = View.Configuration(message: message, deliveryState: message.deliveryState)
    }

    // MARK: Internal

    typealias View = ConversationMessageToolboxCell

    let configuration: View.Configuration

    var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    var showEphemeralTimer = false
    var topMargin: Float = 2
    let isFullWidth = true
    let supportsActions = false
    let containsHighlightableContent = false

    let accessibilityIdentifier: String? = "MessageToolbox"
    let accessibilityLabel: String? = nil
}
