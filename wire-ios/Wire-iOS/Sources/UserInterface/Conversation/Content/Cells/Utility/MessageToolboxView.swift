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
import WireSyncEngine

/// Observes events from the message toolbox.
protocol MessageToolboxViewDelegate: AnyObject {
    func messageToolboxDidRequestOpeningDetails(
        _ messageToolboxView: MessageToolboxView,
        preferredDisplayMode: MessageDetailsDisplayMode
    )
    func messageToolboxViewDidSelectResend(_ messageToolboxView: MessageToolboxView)
    func messageToolboxViewDidSelectDelete(_ sender: UIView?)
}

private extension UILabel {
    static func createSeparatorLabel() -> UILabel {
        let label = UILabel()
        label.numberOfLines = 1
        label.textColor = SemanticColors.Label.baseSecondaryText
        label.font = .preferredFont(forTextStyle: .body)
        label.text = String.MessageToolbox.middleDot
        label.isAccessibilityElement = false
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }
}

/// A view that displays information about a message.

final class MessageToolboxView: UIView {

    /// The object receiving events.
    weak var delegate: MessageToolboxViewDelegate?

    ///
    fileprivate(set) var dataSource: MessageToolboxDataSource?

    // MARK: - UI Elements

    /// The timer for ephemeral messages.
    private var timestampTimer: Timer?

    private let contentStack = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 3
        stack.isAccessibilityElement = false
        stack.alignment = .center
        return stack
    }()

    lazy var font = FontSpec.smallRegularFont.font!
    lazy var color = SemanticColors.Label.textMessageDetails

    lazy var detailsLabel: UILabel = {
        let label = UILabel()
        label.lineBreakMode = .byTruncatingMiddle
        label.numberOfLines = 1
        label.accessibilityIdentifier = "Details"
        label.isAccessibilityElement = true
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.font = font
        label.textColor = color
        return label
    }()

    private lazy var editedLabel: UILabel = {
        let label = UILabel()
        label.lineBreakMode = .byTruncatingMiddle
        label.numberOfLines = 1
        label.accessibilityIdentifier = "Edited"
        label.isAccessibilityElement = true
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.isHidden = true
        label.font = font
        label.textColor = SemanticColors.Label.textMessageDetails

        return label
    }()

    private let timestampSeparatorContainer = UIView()
    private let timestampSeparatorLabel = UILabel.createSeparatorLabel()
    private let statusSeparatorContainer = UIView()
    private let statusSeparatorLabel = UILabel.createSeparatorLabel()

    private lazy var messageFailureView: MessageSendFailureView = {
        let view = MessageSendFailureView()
        view.tapHandler = { [weak self] _ in
            self?.resendMessage()
        }
        return view
    }()

    private lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.lineBreakMode = .byTruncatingMiddle
        label.numberOfLines = 1
        label.accessibilityIdentifier = "DeliveryStatus"
        label.isAccessibilityElement = true
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.font = font
        label.textColor = color
        return label
    }()

    lazy var statusImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.accessibilityIgnoresInvertColors = true
        imageView.tintColor = color
        return imageView
    }()

    lazy var statusContainerView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [statusImageView, statusLabel])
        stackView.spacing = 4
        stackView.isAccessibilityElement = true
        return stackView
    }()

    private lazy var countdownContainer = UIView()
    private lazy var countdownView = {
        let view = DestructionCountdownView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var countdownLabel: UILabel = {
        let label = UILabel()
        label.lineBreakMode = .byTruncatingMiddle
        label.numberOfLines = 1
        label.accessibilityIdentifier = "EphemeralCountdown"
        label.isAccessibilityElement = true
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.font = font
        label.textColor = color
        return label
    }()

    fileprivate var tapGestureRecogniser: UITapGestureRecognizer!
    fileprivate var previousLayoutBounds: CGRect = .zero

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        clipsToBounds = true

        setupViews()
        createConstraints()

        self.tapGestureRecogniser = UITapGestureRecognizer(
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

        timestampSeparatorLabel.translatesAutoresizingMaskIntoConstraints = false
        timestampSeparatorContainer.addSubview(timestampSeparatorLabel)

        statusSeparatorLabel.translatesAutoresizingMaskIntoConstraints = false
        statusSeparatorContainer.addSubview(statusSeparatorLabel)

        countdownContainer = UIView()
        countdownView.translatesAutoresizingMaskIntoConstraints = false
        countdownContainer.addSubview(countdownView)

        [
            detailsLabel,
            timestampSeparatorContainer,
            editedLabel,
            statusContainerView,
            statusSeparatorContainer,
            countdownContainer,
            countdownLabel
        ].forEach(contentStack.addArrangedSubview)

        [
            contentStack,
            messageFailureView
        ].forEach(addSubview)

        statusImageView.constraintToSquare(sideLength: 13)
    }

    private func createConstraints() {
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        messageFailureView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            timestampSeparatorLabel.leadingAnchor.constraint(equalTo: timestampSeparatorContainer.leadingAnchor),
            timestampSeparatorLabel.centerYAnchor.constraint(equalTo: timestampSeparatorContainer.centerYAnchor),
            timestampSeparatorContainer.trailingAnchor.constraint(equalTo: timestampSeparatorLabel.trailingAnchor),

            statusSeparatorLabel.leadingAnchor.constraint(equalTo: statusSeparatorContainer.leadingAnchor),
            statusSeparatorLabel.centerYAnchor.constraint(equalTo: statusSeparatorContainer.centerYAnchor),
            statusSeparatorContainer.trailingAnchor.constraint(equalTo: statusSeparatorLabel.trailingAnchor),

            // statusTextView align vertically center
            contentStack.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            messageFailureView.topAnchor.constraint(equalTo: topAnchor),
            messageFailureView.bottomAnchor.constraint(equalTo: bottomAnchor),
            messageFailureView.leadingAnchor.constraint(equalTo: leadingAnchor),
            messageFailureView.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            countdownView.widthAnchor.constraint(equalToConstant: 10),
            countdownView.heightAnchor.constraint(equalToConstant: 10),
            countdownView.leadingAnchor.constraint(equalTo: countdownContainer.leadingAnchor),
            countdownContainer.trailingAnchor.constraint(equalTo: countdownView.trailingAnchor, constant: 3),
            countdownView.centerYAnchor.constraint(equalTo: countdownContainer.centerYAnchor),
            countdownView.topAnchor.constraint(greaterThanOrEqualTo: countdownContainer.topAnchor),
            countdownContainer.bottomAnchor.constraint(greaterThanOrEqualTo: countdownView.bottomAnchor)
        ])
    }

    // MARK: - Lifecycle

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let message = dataSource?.message else { return }
        guard !bounds.equalTo(previousLayoutBounds) else {
            return
        }

        previousLayoutBounds = bounds
        configureForMessage(message)
    }

    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)

        if newWindow == nil {
            stopCountdownTimer()
        }
    }

    // MARK: - Configuration

    private var contentWidth: CGFloat {
        bounds.width - conversationHorizontalMargins.left - conversationHorizontalMargins.right
    }

    func configureForMessage(
        _ message: ZMConversationMessage,
        animated: Bool = false
    ) {
        if let message = message as? ConversationMessage,
           dataSource?.message.nonce != message.nonce {
            dataSource = MessageToolboxDataSource(message: message)
        }

        reloadContent(animated: animated)
    }

    func setAllContentHidden() {
        contentStack.arrangedSubviews.forEach { $0.isHidden = true }
    }

    private func hideAndCleanStatusLabel() {
        statusLabel.isHidden = true
        statusLabel.accessibilityLabel = nil
        statusLabel.attributedText = nil
    }

    private func reloadContent(animated: Bool) {
        guard let dataSource else { return }

        // Do not reload the content if it didn't change.
        guard dataSource.shouldUpdateContent(
            widthConstraint: contentWidth
        ) else {
            return
        }

        switch dataSource.content {

        case let .callList(callListString):
            detailsLabel.text = callListString
            detailsLabel.isHidden = false
            detailsLabel.numberOfLines = 0
            hideAndCleanStatusLabel()
            timestampSeparatorContainer.isHidden = true
            statusSeparatorContainer.isHidden = true
            countdownContainer.isHidden = true
            countdownLabel.isHidden = true
            messageFailureView.isHidden = true
            editedLabel.isHidden = true

        case let .sendFailure(detailsString):
            hideAndCleanStatusLabel()
            setAllContentHidden()
            messageFailureView.isHidden = false
            messageFailureView.setTitle(detailsString)

        case let .details(timestamp, state, countdown):
            detailsLabel.text = timestamp
            detailsLabel.isHidden = timestamp.isEmpty
            detailsLabel.numberOfLines = 1

            updateState(state)

            timestampSeparatorContainer.isHidden = timestamp.isEmpty || state == nil
            statusSeparatorContainer.isHidden = (timestamp.isEmpty && state == nil) || countdown.isEmpty
            countdownView.setProgress(dataSource.message.countdownProgress ?? 0)
            countdownContainer.isHidden = countdown.isEmpty
            countdownLabel.text = countdown
            countdownLabel.isHidden = countdown.isEmpty

            let editedString = dataSource.editedString
            editedLabel.isHidden = editedString == nil
            editedLabel.text = editedString

            messageFailureView.isHidden = true
        }
    }

    private func updateState(_ state: MessageToolboxState?) {
        statusLabel.isHidden = true
        statusContainerView.isHidden = false
        switch state {
        case .sending:
            statusImageView.image = UIImage(resource: .sending)
            statusContainerView.accessibilityLabel = "sending"
        case .sent:
            statusImageView.image = UIImage(resource: .sent)
            statusContainerView.accessibilityLabel = "sent"
        case .delivered:
            statusImageView.image = UIImage(resource: .delivered)
            statusContainerView.accessibilityLabel = "delivered"
        case .seen:
            statusImageView.image = UIImage(resource: .seen)
            statusContainerView.accessibilityLabel = "seen"
        case let .seenByMultiple(count):
            statusImageView.image = UIImage(resource: .seen)
            statusLabel.isHidden = false
            statusLabel.text = "\(count)"
            statusContainerView.accessibilityLabel = "seen \(count)"
        case nil:
            statusContainerView.isHidden = true
        }
    }

    // MARK: - Timer

    /// Starts the countdown timer.
    func startCountdownTimer() {
        stopCountdownTimer()

        guard let message = dataSource?.message else { return }
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
        guard let dataSource else { return nil }

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
        gestureRecognizer.isEqual(tapGestureRecogniser)
    }

}
