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

final class FailedRecipientsMessageCell: UIView, ConversationMessageCell {

    typealias FailedtosendParticipants = L10n.Localizable.Content.System.FailedtosendParticipants

    struct Configuration {
        let users: [UserType]
        let buttonAction: Completion
    }

    private let failedToSendParticipantsView = FailedToSendParticipantsView()

    weak var delegate: ConversationMessageCellDelegate?
    weak var message: ZMConversationMessage?

    var isSelected: Bool = false

    func configure(with object: Configuration, animated: Bool) {
        let usersCount = 20
        let countString = FailedtosendParticipants.count(usersCount)

        let users = "Bernd Goodwin, Deborah Schoen, Alexandra Olaho, Augustus Quack, Samantha Fox"
        let usersString = FailedtosendParticipants.willGetLater(users)
        let details = FailedtosendParticipants.learnMore(usersString, URL.wr_backendOfflineLearnMore.absoluteString)

        failedToSendParticipantsView.configure(with: usersCount, header: countString, details: details, buttonAction: object.buttonAction)
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
    var mainDetails: String = ""
//    private let stackView = UIStackView(axis: .vertical)
    private let countTextView = WebLinkTextView()
    private let usersTextView = WebLinkTextView()
    private let button: IconButton = {
        let button = InviteButton()
        button.titleLabel?.font = FontSpec.buttonSmallSemibold.font!
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        button.setTitle(FailedtosendParticipants.showDetails, for: .normal)

        return button
    }()

    var buttonAction: Completion?
    private var usersCountBottomConstraint1: NSLayoutConstraint?
    private var usersCountBottomConstraint2: NSLayoutConstraint?

    private var isCollapsed: Bool = false {
        didSet {
            /// Button
            let newTitle = isCollapsed ? FailedtosendParticipants.showDetails : FailedtosendParticipants.hideDetails
            button.setTitle(newTitle, for: .normal)

            /// Users label
            usersTextView.isHidden = isCollapsed
            usersTextView.text = isCollapsed ? "" : mainDetails

            /// Constraints
            if isCollapsed {
                usersCountBottomConstraint1?.isActive = true
                usersCountBottomConstraint2?.isActive = false
            } else {
                usersCountBottomConstraint1?.isActive = false
                usersCountBottomConstraint2?.isActive = true
            }

            layoutIfNeeded()
        }
    }

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

    func configure(with count: Int, header: String, details: String, buttonAction: @escaping Completion) {
        countTextView.attributedText = .markdown(from: header, style: .errorLabelStyle)
        usersTextView.attributedText = .markdown(from: details, style: .errorLabelStyle)
        self.buttonAction = buttonAction

        usersTextView.isHidden = isCollapsed
        mainDetails = details
    }

    // MARK: Setup UI

    private func setupViews() {
//        stackView.setContentHuggingPriority(.defaultHigh, for: .vertical)
//        addSubview(stackView)
//
//        stackView.alignment = .leading
//        stackView.spacing = 2
//        stackView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
//        stackView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
//        [usersCountLabel, usersTextView].forEach(stackView.addArrangedSubview)
//        setContentCompressionResistancePriority(.defaultLow, for: .vertical)



        [countTextView, usersTextView, button].forEach(addSubview)
        button.addTarget(self, action: #selector(detailsButtonTapped), for: .touchUpInside)

        createConstraints()
        setupAccessibility()
    }

    private func createConstraints() {
        //        stackView.translatesAutoresizingMaskIntoConstraints = false
        //        detailsButton.translatesAutoresizingMaskIntoConstraints = false
        //        NSLayoutConstraint.activate([
        //            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 56),
        //            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
        //            stackView.topAnchor.constraint(equalTo: topAnchor),
        //            //stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        //            stackView.bottomAnchor.constraint(equalTo: detailsButton.topAnchor, constant: -4),
        //
        //            detailsButton.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
        //            detailsButton.heightAnchor.constraint(equalToConstant: 25),
        //            detailsButton.bottomAnchor.constraint(equalTo: bottomAnchor)
        //        ])

        countTextView.translatesAutoresizingMaskIntoConstraints = false
        usersTextView.translatesAutoresizingMaskIntoConstraints = false
        button.translatesAutoresizingMaskIntoConstraints = false

        let usersCountBottomConstraint1 = countTextView.bottomAnchor.constraint(equalTo: button.topAnchor, constant: -2)
        let usersCountBottomConstraint2 = countTextView.bottomAnchor.constraint(equalTo: usersTextView.topAnchor, constant: -2)

        NSLayoutConstraint.activate([
            countTextView.topAnchor.constraint(equalTo: topAnchor),
            countTextView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 56),
            countTextView.trailingAnchor.constraint(equalTo: trailingAnchor),
            usersCountBottomConstraint2,

            usersTextView.leadingAnchor.constraint(equalTo: countTextView.leadingAnchor),
            usersTextView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            usersTextView.bottomAnchor.constraint(equalTo: button.topAnchor, constant: -4),

            button.leadingAnchor.constraint(equalTo: countTextView.leadingAnchor),
            button.heightAnchor.constraint(equalToConstant: 25),
            button.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        self.usersCountBottomConstraint1 = usersCountBottomConstraint1
        self.usersCountBottomConstraint2 = usersCountBottomConstraint2
    }

    private func setupAccessibility() {
        countTextView.accessibilityIdentifier = "users_count.label"
        usersTextView.accessibilityIdentifier = "users_list.label"
        button.accessibilityIdentifier = "details.button"
    }

    // MARK: - Methods

    @objc
    func detailsButtonTapped(_ sender: UIButton) {
        isCollapsed = !isCollapsed
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

    init(message: ZMConversationMessage, context: ConversationMessageContext, buttonAction: @escaping Completion) {
        self.configuration = View.Configuration(users: message.failedToSendUsers ?? [], buttonAction: buttonAction)
        actionController = nil
    }

    init(configuration: View.Configuration) {
        self.configuration = configuration
    }

}
