//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

class ConversationSenderMessageCell: UIView, ConversationMessageCell {

    struct Configuration {
        let user: UserType
        let message: ZMConversationMessage
        let indicatorIcon: UIImage?
    }

    weak var delegate: ConversationMessageCellDelegate?
    weak var message: ZMConversationMessage?

    var isSelected: Bool = false

    private let senderView = SenderCellComponent()
    private let indicatorImageView = UIImageView()

    private var indicatorImageViewTrailing: NSLayoutConstraint!

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureSubviews()
        configureConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init?(coder aDecoder: NSCoder) is not implemented")
    }

    func configure(with object: Configuration, animated: Bool) {
        senderView.configure(with: object.user)
        indicatorImageView.isHidden = object.indicatorIcon == nil
        indicatorImageView.image = object.indicatorIcon
    }

    private func configureSubviews() {
        addSubview(senderView)
        addSubview(indicatorImageView)
    }

    private func configureConstraints() {
        senderView.translatesAutoresizingMaskIntoConstraints = false
        indicatorImageView.translatesAutoresizingMaskIntoConstraints = false

        indicatorImageViewTrailing = indicatorImageView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor,
                                                                                  constant: -conversationHorizontalMargins.right)

        NSLayoutConstraint.activate([
            // indicatorImageView
            indicatorImageViewTrailing,
            indicatorImageView.centerYAnchor.constraint(equalTo: centerYAnchor),

            // senderView
            senderView.leadingAnchor.constraint(equalTo: leadingAnchor),
            senderView.topAnchor.constraint(equalTo: topAnchor),
            senderView.trailingAnchor.constraint(equalTo: indicatorImageView.leadingAnchor, constant: -8),
            senderView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        indicatorImageViewTrailing.constant = -conversationHorizontalMargins.right
    }

}

class ConversationSenderMessageCellDescription: ConversationMessageCellDescription {
    typealias View = ConversationSenderMessageCell
    typealias ConversationAnnouncement = L10n.Accessibility.ConversationAnnouncement
    let configuration: View.Configuration

    var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    var showEphemeralTimer: Bool = false
    var topMargin: Float = 16

    let isFullWidth: Bool = true
    let supportsActions: Bool = false
    let containsHighlightableContent: Bool = false

    let accessibilityIdentifier: String? = nil
    var accessibilityLabel: String?

    init(sender: UserType, message: ZMConversationMessage) {
        self.message = message

        var icon: UIImage?
        let iconColor = SemanticColors.Icon.foregroundDefault

        if message.isDeletion {
            icon = StyleKitIcon.trash.makeImage(size: 8, color: iconColor)
        } else if message.updatedAt != nil {
            icon = StyleKitIcon.pencil.makeImage(size: 8, color: iconColor)
        }

        self.configuration = View.Configuration(user: sender, message: message, indicatorIcon: icon)
        setupAccessibility(sender)
        actionController = nil
    }

    private func setupAccessibility(_ sender: UserType) {
        guard let message = message, let senderName = sender.name else {
            accessibilityLabel = nil
            return
        }
        if message.isDeletion {
            accessibilityLabel = ConversationAnnouncement.DeletedMessage.description(senderName)
        } else if message.updatedAt != nil {
            if message.isText, let textMessageData = message.textMessageData {
                let messageText = NSAttributedString.format(message: textMessageData, isObfuscated: message.isObfuscated)
                accessibilityLabel = ConversationAnnouncement.EditedMessage.description(senderName) + messageText.string
            } else {
                accessibilityLabel = ConversationAnnouncement.EditedMessage.description(senderName)
            }
        } else {
            accessibilityLabel = nil
        }
    }

}

final class FailedRecipientsMessageCell: UIView, ConversationMessageCell {

    typealias FailedtosendParticipants = L10n.Localizable.Content.System.FailedtosendParticipants

    struct Configuration {
        let users: [UserType]
    }

    private let failedToSendParticipantsView = FailedToSendParticipantsView()

    weak var delegate: ConversationMessageCellDelegate?
    weak var message: ZMConversationMessage?

    var isSelected: Bool = false

    func configure(with object: Configuration, animated: Bool) {
        var usersString: String = ""
        if object.users.count > 1 {
            usersString = FailedtosendParticipants.count(object.users.count)
        } else {
            if let first = object.users.first,
               let name = first.name {
                usersString = FailedtosendParticipants.willGetLater(name)
            }
        }

        ///
        let header = FailedtosendParticipants.count(20)
        let testUsers = "Bernd Goodwin, Deborah Schoen, Alexandra Olaho, Augustus Quack, Samantha Fox"
        usersString = FailedtosendParticipants.willGetLater(testUsers)
        let usr = FailedtosendParticipants.learnMore(usersString, URL.wr_backendOfflineLearnMore.absoluteString)
        failedToSendParticipantsView.configure(with: 20, header: header, details: usr, delegate: delegate)
        ///

//        let usr = FailedtosendParticipants.learnMore(usersString, URL.wr_backendOfflineLearnMore.absoluteString)
//        failedToSendParticipantsView.configure(with: object.users.count, header: usr, details: "", delegate: delegate)
    }

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
        addSubview(failedToSendParticipantsView)
    }

    private func configureConstraints() {
        failedToSendParticipantsView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            failedToSendParticipantsView.leadingAnchor.constraint(equalTo: leadingAnchor),
            failedToSendParticipantsView.topAnchor.constraint(equalTo: topAnchor),
            failedToSendParticipantsView.trailingAnchor.constraint(equalTo: trailingAnchor),
            failedToSendParticipantsView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

}

final class FailedToSendParticipantsView: UIView {

    typealias FailedtosendParticipants = L10n.Localizable.Content.System.FailedtosendParticipants

    // MARK: Properties
    weak var delegate: ConversationMessageCellDelegate?
    private let stackView = UIStackView(axis: .vertical)
    private let usersCountLabel = WebLinkTextView()
    private let usersTextView = WebLinkTextView()
    private let detailsButton: IconButton = {
        let button = InviteButton()
        button.titleLabel?.font = FontSpec.buttonSmallSemibold.font!
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        button.setTitle(FailedtosendParticipants.showDetails, for: .normal)

        return button
    }()

    private var isCollapsed: Bool = true {
        didSet {
            let newTitle = isCollapsed ? FailedtosendParticipants.showDetails : FailedtosendParticipants.hideDetails
            detailsButton.setTitle(newTitle, for: .normal)
            UIView.performWithoutAnimation {
                usersTextView.isHidden = isCollapsed
            }
            layoutIfNeeded()
            setNeedsLayout()
            //delegate?.updateLayout()
        }
    }
    //weak var delegate: IconActionCellDelegate?

    // MARK: initialization

    override init(frame: CGRect) {
        super.init(frame: CGRect.zero)

        setupViews()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configuration

    func configure(with count: Int, header: String, details: String, delegate: ConversationMessageCellDelegate?) {
        let isMultiple = count > 1
        detailsButton.isHidden = !isMultiple
        usersTextView.isHidden = !isMultiple

        let countText = L10n.Localizable.Content.System.FailedtosendParticipants.count(count)
        usersCountLabel.attributedText = isMultiple
                                        ? .markdown(from: countText, style: .errorLabelStyle)
                                        : .markdown(from: header, style: .errorLabelStyle)
        usersTextView.attributedText = .markdown(from: details, style: .errorLabelStyle)
        self.delegate = delegate
    }

    // MARK: Setup UI

    private func setupViews() {
//        stackView.setContentHuggingPriority(.defaultHigh, for: .vertical)
//        addSubview(stackView)
//
//        stackView.alignment = .leading
//        stackView.spacing = 4
//        stackView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
//        stackView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
//        [usersCountLabel, usersLabel, detailsButton].forEach(stackView.addArrangedSubview)
//        setContentCompressionResistancePriority(.defaultLow, for: .vertical)

        [usersCountLabel, usersTextView, detailsButton].forEach(addSubview)
        detailsButton.addTarget(self, action: #selector(detailsButtonTapped), for: .touchUpInside)

        createConstraints()
        setupAccessibility()
    }

    private func createConstraints() {
//                stackView.translatesAutoresizingMaskIntoConstraints = false
//                NSLayoutConstraint.activate([
//                    stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
//                    stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
//                    stackView.topAnchor.constraint(equalTo: topAnchor),
//                    //stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
//                ])
        usersCountLabel.translatesAutoresizingMaskIntoConstraints = false
        detailsButton.translatesAutoresizingMaskIntoConstraints = false
        usersTextView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            usersCountLabel.topAnchor.constraint(equalTo: topAnchor),
            usersCountLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 56),
            usersCountLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            // usersCountLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
            usersCountLabel.bottomAnchor.constraint(equalTo: usersTextView.topAnchor, constant: -2),

            usersTextView.leadingAnchor.constraint(equalTo: usersCountLabel.leadingAnchor),
            usersTextView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            usersTextView.bottomAnchor.constraint(equalTo: detailsButton.topAnchor, constant: -8),

            detailsButton.leadingAnchor.constraint(equalTo: usersCountLabel.leadingAnchor),
            detailsButton.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func setupAccessibility() {
        usersCountLabel.accessibilityIdentifier = "users_count.label"
        usersTextView.accessibilityIdentifier = "users_list.label"
        detailsButton.accessibilityIdentifier = "details.button"
    }

    // MARK: - Methods

    @objc
    func detailsButtonTapped(_ sender: UIButton) {
        isCollapsed = !isCollapsed
    }

}

class ConversationMessageFailedRecipientsCellDescription: ConversationMessageCellDescription {

    typealias View = FailedRecipientsMessageCell
    let configuration: View.Configuration

    weak var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?
    weak var sectionDelegate: ConversationMessageSectionControllerDelegate?

    var showEphemeralTimer: Bool = false
    var topMargin: Float = 5

    var isFullWidth: Bool = true
    var supportsActions: Bool = false
    var containsHighlightableContent: Bool = false

    var accessibilityIdentifier: String? = nil
    var accessibilityLabel: String? = nil

    init(message: ZMConversationMessage, context: ConversationMessageContext) {
        self.configuration = View.Configuration(users: message.failedToSendUsers ?? [])
        actionController = nil
    }

    init(configuration: View.Configuration) {
        self.configuration = configuration
    }

}
