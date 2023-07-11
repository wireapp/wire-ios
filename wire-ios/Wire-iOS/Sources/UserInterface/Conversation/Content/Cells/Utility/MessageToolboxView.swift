//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
import WireSyncEngine
import WireDataModel

/// Observes events from the message toolbox.
protocol MessageToolboxViewDelegate: AnyObject {
    func messageToolboxDidRequestOpeningDetails(_ messageToolboxView: MessageToolboxView, preferredDisplayMode: MessageDetailsDisplayMode)
    func messageToolboxViewDidSelectResend(_ messageToolboxView: MessageToolboxView)
    func messageToolboxViewDidSelectDelete(_ sender: UIView?)
}

private extension UILabel {
    static func createSeparatorLabel() -> UILabel {
        let label = UILabel()
        label.numberOfLines = 1
        label.textColor = SemanticColors.View.backgroundSeparatorCell
        label.font = UIFont.smallSemiboldFont
        label.text = String.MessageToolbox.middleDot
        label.isAccessibilityElement = false
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }
}

/**
 * A view that displays information about a message.
 */

final class MessageToolboxView: UIView {

    /// The object receiving events.
    weak var delegate: MessageToolboxViewDelegate?

    ///
    fileprivate(set) var dataSource: MessageToolboxDataSource?

    // MARK: - UI Elements

    /// The timer for ephemeral messages.
    private var timestampTimer: Timer?

    typealias MessageActionsColor = SemanticColors.Label

    private let contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 3
        stack.isAccessibilityElement = false
        return stack
    }()

    private let detailsLabel: UILabel = {
        let label = UILabel()
        label.lineBreakMode = .byTruncatingMiddle
        label.numberOfLines = 1
        label.accessibilityIdentifier = "Details"
        label.isAccessibilityElement = true
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    private let timestampSeparatorLabel = UILabel.createSeparatorLabel()
    private let statusSeparatorLabel = UILabel.createSeparatorLabel()

    private let resendButton: UIButton = {
        let button = UIButton()
        let attributedTitle = NSAttributedString(string: "content.system.failedtosend_message_timestamp_resend".localized,
                                                 attributes: [.foregroundColor: MessageActionsColor.textErrorDefault,
                                                              .underlineStyle: NSUnderlineStyle.single.rawValue as NSNumber,
                                                              .font: UIFont.smallSemiboldFont])

        button.contentHorizontalAlignment = .left
        button.setAttributedTitle(attributedTitle, for: .normal)
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        return button
    }()

    private let deleteButton: UIButton = {
        let button = UIButton()
        let attributedTitle = NSAttributedString(string: "content.system.failedtosend_message_timestamp_delete".localized,
                                                 attributes: [.foregroundColor: MessageActionsColor.textErrorDefault,
                                                              .underlineStyle: NSUnderlineStyle.single.rawValue as NSNumber,
                                                              .font: UIFont.smallSemiboldFont])

        button.contentHorizontalAlignment = .left
        button.setAttributedTitle(attributedTitle, for: .normal)
        button.setContentHuggingPriority(.defaultLow, for: .horizontal)
        button.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return button
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.lineBreakMode = .byTruncatingMiddle
        label.numberOfLines = 1
        label.accessibilityIdentifier = "DeliveryStatus"
        label.isAccessibilityElement = true
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    private let countdownLabel: UILabel = {
        let label = UILabel()
        label.lineBreakMode = .byTruncatingMiddle
        label.numberOfLines = 1
        label.accessibilityIdentifier = "EphemeralCountdown"
        label.isAccessibilityElement = true
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    fileprivate var tapGestureRecogniser: UITapGestureRecognizer!

    fileprivate let separatorView = UIView()
    fileprivate var likeButtonWidth: NSLayoutConstraint!
    fileprivate var heightConstraint: NSLayoutConstraint!
    fileprivate var previousLayoutBounds: CGRect = CGRect.zero
    fileprivate var forceShowTimestamp: Bool = false

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        clipsToBounds = true

        setupViews()
        createConstraints()

        tapGestureRecogniser = UITapGestureRecognizer(
            target: self,
            action: #selector(MessageToolboxView.onTapContent(_:))
        )
        tapGestureRecogniser.delegate = self
        addGestureRecognizer(tapGestureRecogniser)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {

        resendButton.addTarget(self, action: #selector(resendMessage), for: .touchUpInside)
        deleteButton.addTarget(self, action: #selector(deleteMessage), for: .touchUpInside)

        [detailsLabel,
         resendButton,
         timestampSeparatorLabel,
         deleteButton,
         statusLabel,
         statusSeparatorLabel,
         countdownLabel].forEach(contentStack.addArrangedSubview)
        [separatorView, contentStack].forEach(addSubview)
    }

    private func createConstraints() {
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        heightConstraint = heightAnchor.constraint(greaterThanOrEqualToConstant: 28)
        heightConstraint.priority = UILayoutPriority(999)

        NSLayoutConstraint.activate([
            heightConstraint,

            separatorView.widthAnchor.constraint(equalToConstant: conversationHorizontalMargins.left),
            separatorView.leadingAnchor.constraint(equalTo: leadingAnchor),
            separatorView.topAnchor.constraint(equalTo: topAnchor),
            separatorView.bottomAnchor.constraint(equalTo: bottomAnchor),

            // statusTextView align vertically center
            contentStack.leadingAnchor.constraint(equalTo: separatorView.trailingAnchor),
            contentStack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -conversationHorizontalMargins.right),
            contentStack.topAnchor.constraint(equalTo: topAnchor),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    // MARK: - Lifecycle

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let message = self.dataSource?.message else { return }
        guard !self.bounds.equalTo(self.previousLayoutBounds) else {
            return
        }

        self.previousLayoutBounds = self.bounds
        self.configureForMessage(message)
    }

    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)

        if newWindow == nil {
            stopCountdownTimer()
        }
    }

    func prepareForReuse() {
        dataSource = nil
        stopCountdownTimer()
    }

    // MARK: - Configuration

    private var contentWidth: CGFloat {
        return bounds.width - conversationHorizontalMargins.left - conversationHorizontalMargins.right
    }

    func configureForMessage(
        _ message: ZMConversationMessage,
        animated: Bool = false
    ) {
        if dataSource?.message.nonce != message.nonce {
            dataSource = MessageToolboxDataSource(message: message)
        }

        reloadContent(animated: animated)
    }

    private func hideAndCleanStatusLabel() {
        statusLabel.isHidden = true
        statusLabel.accessibilityLabel = nil
        statusLabel.attributedText = nil
    }

    private func reloadContent(animated: Bool) {
        guard let dataSource = self.dataSource else { return }

        // Do not reload the content if it didn't change.
        guard dataSource.uppdateContent(
            widthConstraint: contentWidth
        ) else {
            return
        }

        switch dataSource.content {

        case .callList(let callListString):
            self.detailsLabel.attributedText = callListString
            self.detailsLabel.isHidden = false
            self.detailsLabel.numberOfLines = 0
            self.hideAndCleanStatusLabel()
            self.timestampSeparatorLabel.isHidden = true
            self.deleteButton.isHidden = true
            self.resendButton.isHidden = true
            self.statusSeparatorLabel.isHidden = true
            self.countdownLabel.isHidden = true

        case .sendFailure(let detailsString):
            self.detailsLabel.attributedText = detailsString
            self.detailsLabel.isHidden = false
            self.detailsLabel.numberOfLines = 1
            self.hideAndCleanStatusLabel()
            self.timestampSeparatorLabel.isHidden = false
            self.deleteButton.isHidden = false
            self.resendButton.isHidden = false
            self.statusSeparatorLabel.isHidden = true
            self.countdownLabel.isHidden = true

        case .details(let timestamp, let status, let countdown):
            self.detailsLabel.attributedText = timestamp
            self.detailsLabel.isHidden = timestamp == nil
            self.detailsLabel.numberOfLines = 1
            self.statusLabel.attributedText = status
            // override accessibilityLabel if the attributed string has customized accessibilityLabel
            if let accessibilityLabel = status?.accessibilityLabel {
                self.statusLabel.accessibilityLabel = accessibilityLabel
            }
            self.statusLabel.isHidden = status == nil
            self.timestampSeparatorLabel.isHidden = timestamp == nil || status == nil
            self.deleteButton.isHidden = true
            self.resendButton.isHidden = true
            self.statusSeparatorLabel.isHidden = (timestamp == nil && status == nil) || countdown == nil
            self.countdownLabel.attributedText = countdown
            self.countdownLabel.isHidden = countdown == nil

        }

        layoutIfNeeded()
    }

    // MARK: - Timer

    /// Starts the countdown timer.
    func startCountdownTimer() {
        stopCountdownTimer()

        guard let message = self.dataSource?.message else { return }
        guard message.isEphemeral, !message.hasBeenDeleted, !message.isObfuscated else { return }

        timestampTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.reloadContent(animated: false)
        }
    }

    /// Stops the countdown timer.
    func stopCountdownTimer() {
        timestampTimer?.invalidate()
        timestampTimer = nil
    }

    // MARK: - Actions

    @objc
    private func resendMessage() {
        delegate?.messageToolboxViewDidSelectResend(self)
    }

    @objc
    private func deleteMessage(sender: UIView?) {
        delegate?.messageToolboxViewDidSelectDelete(sender)
    }

}

// MARK: - Tap Gesture

extension MessageToolboxView: UIGestureRecognizerDelegate {

    @objc
    func onTapContent(_ sender: UITapGestureRecognizer!) {
        if let displayMode = preferredDetailsDisplayMode() {
            delegate?.messageToolboxDidRequestOpeningDetails(self, preferredDisplayMode: displayMode)
        }
    }

    func preferredDetailsDisplayMode() -> MessageDetailsDisplayMode? {
        guard let dataSource = self.dataSource else { return nil }

        switch dataSource.content {
        case .sendFailure:
            break
        case .details where dataSource.message.areReadReceiptsDetailsAvailable:
            return .receipts
        default:
            break
        }

        return nil
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return gestureRecognizer.isEqual(self.tapGestureRecogniser)
    }

}
