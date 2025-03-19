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

import WireDesign
import WireSyncEngine

final class ConversationCollapsedMessageCell: UIView, ConversationMessageCell {

    struct Configuration {
        let message: ZMConversationMessage
        let user: UserType?
        let collapseExpandAction: () -> Void
        let errorMessage: String?
    }

    var isSelected: Bool = false

    weak var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    private lazy var avatar: UserImageView = {
        let view = UserImageView()
        view.userSession = ZMUserSession.shared()
        view.initialsFont = .avatarInitial
        view.size = .badge
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tappedOnAvatar)))
        view.accessibilityElementsHidden = false
        view.isAccessibilityElement = true
        view.accessibilityTraits = .button
        view.accessibilityLabel = L10n.Accessibility.Conversation.ProfileImage.description
        view.accessibilityHint = L10n.Accessibility.Conversation.ProfileImage.hint
        view.isUserInteractionEnabled = true
        view.setContentHuggingPriority(.required, for: .horizontal)
        view.setContentCompressionResistancePriority(.required, for: .horizontal)

        return view
    }()

    private lazy var messageTextView: LinkInteractionTextView = {
        let view = LinkInteractionTextView()

        view.isEditable = false
        view.isSelectable = false
        view.backgroundColor = .clear
        view.isScrollEnabled = false
        view.textContainerInset = UIEdgeInsets.zero
        view.textContainer.lineFragmentPadding = 0
        view.isUserInteractionEnabled = false
        view.accessibilityIdentifier = "Message"
        view.accessibilityElementsHidden = false
        view.dataDetectorTypes = [.link, .address, .phoneNumber, .flightNumber, .calendarEvent, .shipmentTrackingNumber]
        view.linkTextAttributes = [.foregroundColor: UIColor.accent()]
        view.setContentHuggingPriority(.required, for: .vertical)
        view.setContentCompressionResistancePriority(.required, for: .vertical)

        view.textContainer.maximumNumberOfLines = 1
        view.isScrollEnabled = false
        view.textContainer.lineBreakMode = .byTruncatingTail

        return view
    }()

    private lazy var typeIcon: UIImageView = {
        let view = UIImageView(image: .init(resource: .file))
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setContentHuggingPriority(.required, for: .horizontal)
        view.setContentCompressionResistancePriority(.required, for: .horizontal)
        view.isUserInteractionEnabled = false
        view.tintColor = ColorTheme.Backgrounds.onSurfaceVariant
        return view
    }()

    private lazy var collapseButton: UIButton = {
        let button = UIButton()
        let image = UIImage(resource: .collapse)
        button.setImage(image, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isUserInteractionEnabled = false
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.tintColor = SemanticColors.Label.baseSecondaryText
        return button
    }()
    
    private let messageFailureView = MessageSendFailureView()
        .setIsHidden(true)

    private lazy var wholeViewTapButton = UIButton()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureSubviews()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with object: Configuration, animated: Bool) {
        let user = object.user
        avatar.user = user

        let message = object.message
        if message.isText {
            typeIcon.isHidden = true
            if let textMessageData = message.textMessageData {
                messageTextView.attributedText = NSAttributedString
                    .format(
                        message: textMessageData,
                        isObfuscated: message.isObfuscated
                    )
            }
        } else {
            messageTextView.font = UIFont.italicSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .body).pointSize)
            typeIcon.isHidden = false
            if message.isImage {
                typeIcon.image = .init(resource: .image)
                messageTextView.text = L10n.Localizable.Content.Collapsed.Image.title
            } else if message.isVideo {
                typeIcon.image = .init(resource: .play)
                messageTextView.text = L10n.Localizable.Content.Collapsed.Video.title
            } else if message.isAudio {
                typeIcon.image = .init(resource: .micOn)
                messageTextView.text = L10n.Localizable.Content.Collapsed.Audio.title
            } else if message.isLocation {
                typeIcon.image = .init(resource: .location)
                messageTextView.text = L10n.Localizable.Content.Collapsed.Location.title
            } else if message.isFile {
                typeIcon.image = .init(resource: .file)
                messageTextView.text = L10n.Localizable.Content.Collapsed.File.title
            }
        }
        
        if let errorMessage = object.errorMessage {
            messageFailureView.isHidden = false
            messageFailureView.setTitle(errorMessage)
        } else {
            messageFailureView.isHidden = true
        }

        wholeViewTapButton.removeTarget(nil, action: nil, for: .allEvents)
        let action = UIAction { _ in
            object.collapseExpandAction()
        }
        wholeViewTapButton.addAction(action, for: .touchUpInside)
    }

    private func configureSubviews() {

        let margins = conversationHorizontalMargins

        addSubview(wholeViewTapButton)
        wholeViewTapButton.pin(to: self)

        let horizontalStack = UIStackView.horizontal(
            views: [
                avatar.wrapInView(leadingInset: margins.left - 36, bottomInset: -7),
                messageTextView,
                [typeIcon, collapseButton.wrapInView(trailingInset: margins.right)]
                    .horizontalStack(spacing: 8)
                    .wrapInView(bottomInset: -1)
            ],
            spacing: 10,
            alignment: .center
        ).setTranslatesAutoresizingMaskIntoConstraints(false)
            .setIsUserInteractionEnabled(false)
        
        let stack = [horizontalStack,
                     messageFailureView.wrapInView(leadingInset: margins.left,trailingInset: margins.right)]
            .verticalStack()
            .setTranslatesAutoresizingMaskIntoConstraints(false)
            .setIsUserInteractionEnabled(false)
            
        addSubview(stack)

        horizontalStack.heightConstraint(38)
        
        stack.pin(to: self)

        typeIcon.constraintToSquare(sideLength: 16)
    }

    // MARK: - Tap gesture of avatar

    @objc
    func tappedOnAvatar() {
        guard let user = avatar.user else { return }

        SessionManager.shared?.showUserProfile(user: user)
    }
}

final class ConversationCollapsedMessageCellDescription: ConversationMessageCellDescription {

    typealias View = ConversationCollapsedMessageCell

    let configuration: View.Configuration

    var topMargin: CGFloat = 8
    var showEphemeralTimer: Bool = false

    let supportsActions: Bool = true
    let containsHighlightableContent: Bool = false

    weak var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    var accessibilityIdentifier: String? {
        "CollapsedFileCell"
    }

    let accessibilityLabel: String? = nil

    init(
        message: ConversationMessage,
        collapseExpandAction: @escaping () -> Void
    ) {
        self.configuration = View.Configuration(
            message: message,
            user: message.senderUser,
            collapseExpandAction: collapseExpandAction,
            errorMessage: MessageErrorHelper.errorMessage(message)
        )
    }

}
