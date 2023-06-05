//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

final class FailedRecipientsMessageCell1: UIView, ConversationMessageCell {

    typealias FailedtosendParticipants = L10n.Localizable.Content.System.FailedtosendParticipants

    struct Configuration {
        let title: String
        let content: String
        let isCollapsed: Bool
        let hasMultipleUsers: Bool
        let buttonAction: Completion
    }

    // MARK: - Properties

    weak var delegate: ConversationMessageCellDelegate?
    weak var message: ZMConversationMessage?
    var isSelected: Bool = true

    private var isCollapsed: Bool = true
    private var buttonAction: Completion?

    private let contentStackView = UIStackView(axis: .vertical)
    private let stackView = UIStackView(axis: .vertical)
    private let totalCountView = WebLinkTextView()
    private let usersView = WebLinkTextView()
    private let imageContainer = UIView()
    private let imageView = UIImageView()
    private let button = InviteButton(fontSpec: FontSpec.buttonSmallSemibold,
                                      insets: UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8))

    private var config: Configuration? {
        didSet {
            updateUI()
        }
    }

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupViews()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init?(coder aDecoder: NSCoder) is not implemented")
    }

    // MARK: - Setup UI

    func configure(with object: Configuration, animated: Bool) {
        self.config = object
    }

    private func updateUI() {
        guard let config = config else {
            return
        }

        isCollapsed = config.isCollapsed
        buttonAction = config.buttonAction

        guard config.hasMultipleUsers else {
            usersView.attributedText = .markdown(from: config.content, style: .errorLabelStyle)
            [totalCountView, button].forEach { $0.isHidden = true }
            return
        }

        [totalCountView, button].forEach { $0.isHidden = false }
        usersView.isHidden = isCollapsed
        totalCountView.attributedText = .markdown(from: config.title, style: .errorLabelStyle)
        usersView.attributedText = .markdown(from: config.content, style: .errorLabelStyle)
        setupButtonTitle()

        layoutIfNeeded()
    }

    private func setupButtonTitle() {
        let buttonTitle = isCollapsed ? FailedtosendParticipants.showDetails : FailedtosendParticipants.hideDetails
        button.setTitle(buttonTitle, for: .normal)
    }

    private func setupViews() {
        addSubview(stackView)

        contentStackView.alignment = .leading
        contentStackView.spacing = 2
        usersView.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 0)
        [totalCountView, usersView].forEach(contentStackView.addArrangedSubview)

        stackView.alignment = .leading
        stackView.spacing = 8
        [contentStackView, button].forEach(stackView.addArrangedSubview)

        button.setTitle(FailedtosendParticipants.showDetails, for: .normal)
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)

        imageContainer.addSubview(imageView)
        addSubview(imageContainer)
        imageView.image =  Asset.Images.attention.image.withTintColor(SemanticColors.Label.textErrorDefault)

        createConstraints()
        setupAccessibility()
    }

    private func createConstraints() {
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        imageContainer.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        totalCountView.translatesAutoresizingMaskIntoConstraints = false
        usersView.translatesAutoresizingMaskIntoConstraints = false
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: conversationHorizontalMargins.left),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -conversationHorizontalMargins.right),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),

            imageContainer.widthAnchor.constraint(equalToConstant: conversationHorizontalMargins.left),
            imageContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageContainer.topAnchor.constraint(equalTo: stackView.topAnchor),
            imageContainer.heightAnchor.constraint(equalTo: imageView.heightAnchor),

            // imageView
            imageView.centerXAnchor.constraint(equalTo: imageContainer.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: imageContainer.centerYAnchor)
        ])
    }

    private func setupAccessibility() {
        totalCountView.accessibilityIdentifier = "total_count.label"
        usersView.accessibilityIdentifier = "users_list.label"
        button.accessibilityIdentifier = "details.button"
    }

    // MARK: - Methods

    @objc
    func buttonTapped(_ sender: UIButton) {
        buttonAction?()
    }

}

final class FailedRecipientsMessageCell: UIView, ConversationMessageCell {

    typealias FailedtosendParticipants = L10n.Localizable.Content.System.FailedtosendParticipants
    typealias FailedParticipants = L10n.Localizable.Content.System.FailedParticipants

    struct Configuration {
        let users: [UserType]
        let buttonAction: Completion
        let isCollapsed: Bool
    }

    // MARK: - Properties

    weak var delegate: ConversationMessageCellDelegate?
    weak var message: ZMConversationMessage?
    var isSelected: Bool = true

    private var isCollapsed: Bool = true
    private var buttonAction: Completion?

    private let contentStackView = UIStackView(axis: .vertical)
    private let stackView = UIStackView(axis: .vertical)
    private let totalCountView = WebLinkTextView()
    private let usersView = WebLinkTextView()
    private let button = InviteButton(fontSpec: FontSpec.buttonSmallSemibold,
                                      insets: UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8))

    private var config: Configuration? {
        didSet {
            updateUI()
        }
    }

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupViews()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init?(coder aDecoder: NSCoder) is not implemented")
    }

    // MARK: - Setup UI

    func configure(with object: Configuration, animated: Bool) {
        self.config = object
    }

    private func updateUI() {
        guard let config = config else {
            return
        }

        isCollapsed = config.isCollapsed
        buttonAction = config.buttonAction
        let content = configureContent(for: config.users)

        guard config.users.count > 1 else {
            usersView.attributedText = .markdown(from: content.details, style: .errorLabelStyle)
            [totalCountView, button].forEach { $0.isHidden = true }
            return
        }

        [totalCountView, button].forEach { $0.isHidden = false }
        usersView.isHidden = isCollapsed
        totalCountView.attributedText = .markdown(from: content.count, style: .errorLabelStyle)
        usersView.attributedText = .markdown(from: content.details, style: .errorLabelStyle)
        setupButtonTitle()

        layoutIfNeeded()
    }

    private func configureContent(for users: [UserType]) -> (count: String, details: String) {
        let totalCountText = FailedtosendParticipants.count(users.count)

        let userNames = users.compactMap { $0.name }.joined(separator: ", ")
        let detailsText = FailedtosendParticipants.willGetLater(userNames)
        let detailsWithLinkText = FailedParticipants.learnMore(detailsText, URL.wr_backendOfflineLearnMore.absoluteString)

        return (totalCountText, detailsWithLinkText)
    }

    private func setupButtonTitle() {
        let buttonTitle = isCollapsed ? FailedtosendParticipants.showDetails : FailedtosendParticipants.hideDetails
        button.setTitle(buttonTitle, for: .normal)
    }

    private func setupViews() {
        addSubview(stackView)

        contentStackView.alignment = .leading
        contentStackView.spacing = 2
        usersView.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 0)
        [totalCountView, usersView].forEach(contentStackView.addArrangedSubview)

        stackView.alignment = .leading
        stackView.spacing = 8
        [contentStackView, button].forEach(stackView.addArrangedSubview)

        button.setTitle(FailedtosendParticipants.showDetails, for: .normal)
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)

        createConstraints()
        setupAccessibility()
    }

    private func createConstraints() {
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        totalCountView.translatesAutoresizingMaskIntoConstraints = false
        usersView.translatesAutoresizingMaskIntoConstraints = false
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: conversationHorizontalMargins.left),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -conversationHorizontalMargins.right),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func setupAccessibility() {
        totalCountView.accessibilityIdentifier = "total_count.label"
        usersView.accessibilityIdentifier = "users_list.label"
        button.accessibilityIdentifier = "details.button"
    }

    // MARK: - Methods

    @objc
    func buttonTapped(_ sender: UIButton) {
        buttonAction?()
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

    init(failedRecipients: [UserType], buttonAction: @escaping Completion, isCollapsed: Bool) {
        configuration = View.Configuration(users: failedRecipients,
                                           buttonAction: buttonAction,
                                           isCollapsed: isCollapsed)
    }

    init(configuration: View.Configuration) {
        self.configuration = configuration
    }

}
