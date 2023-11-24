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
import WireSyncEngine
import WireCommonComponents

typealias ContactsCellActionButtonHandler = (UserType, ContactsCell.Action) -> Void

/// A UITableViewCell version of UserCell, with simpler functionality for contact Screen with table view index bar
final class ContactsCell: UITableViewCell, SeparatorViewProtocol {
    var user: UserType? {
        didSet {
            avatar.user = user
            updateTitleLabel()

            if let subtitle = subtitle(forRegularUser: user), subtitle.length > 0 {
                subtitleLabel.isHidden = false
                subtitleLabel.attributedText = subtitle
            } else {
                subtitleLabel.isHidden = true
            }
        }
    }

    static let boldFont: FontSpec = .smallRegularFont
    static let lightFont: FontSpec = .smallLightFont

    typealias ViewColors = SemanticColors.View
    typealias LabelColors = SemanticColors.Label

    let avatar: BadgeUserImageView = {
        let badgeUserImageView = BadgeUserImageView()
        badgeUserImageView.userSession = ZMUserSession.shared()
        badgeUserImageView.initialsFont = .avatarInitial
        badgeUserImageView.size = .small
        badgeUserImageView.translatesAutoresizingMaskIntoConstraints = false

        return badgeUserImageView
    }()

    let avatarSpacer = UIView()
    let buttonSpacer = UIView()

    let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSpec.normalLightFont.font!
        label.accessibilityIdentifier = "contact_cell.name"

        return label
    }()

    let subtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSpec.smallRegularFont.font!
        label.accessibilityIdentifier = "contact_cell.username"

        return label
    }()

    var action: Action? {
        didSet {
            actionButton.setTitle(action?.localizedDescription, for: .normal)
        }
    }

    let actionButton: Button = Button(style: .accentColorTextButtonStyle,
                                      cornerRadius: 4,
                                      fontSpec: .mediumSemiboldFont)

    var actionButtonHandler: ContactsCellActionButtonHandler?

    private lazy var actionButtonWidth: CGFloat = {
        guard let font = actionButton.titleLabel?.font else { return 0 }

        let transform = actionButton.textTransform
        let insets = actionButton.contentEdgeInsets

        let titleWidths: [CGFloat] = [Action.open, .invite].map {
            let title = $0.localizedDescription
            let transformedTitle = title.applying(transform: transform)
            return transformedTitle.size(withAttributes: [.font: font]).width
        }

        let maxWidth = titleWidths.max()!
        return CGFloat(ceilf(Float(insets.left + maxWidth + insets.right)))
    }()

    var titleStackView: UIStackView!
    var contentStackView: UIStackView!

    // SeparatorCollectionViewCell
    let separator = UIView()
    var separatorInsetConstraint: NSLayoutConstraint!
    var separatorLeadingInset: CGFloat = 64 {
        didSet {
            separatorInsetConstraint?.constant = separatorLeadingInset
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureSubviews()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setUp() {
        avatarSpacer.addSubview(avatar)
        avatarSpacer.translatesAutoresizingMaskIntoConstraints = false

        buttonSpacer.addSubview(actionButton)
        buttonSpacer.translatesAutoresizingMaskIntoConstraints = false

        titleStackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        titleStackView.axis = .vertical
        titleStackView.distribution = .equalSpacing
        titleStackView.alignment = .leading
        titleStackView.translatesAutoresizingMaskIntoConstraints = false

        contentStackView = UIStackView(arrangedSubviews: [avatarSpacer, titleStackView, buttonSpacer])
        contentStackView.axis = .horizontal
        contentStackView.distribution = .fill
        contentStackView.alignment = .center
        contentStackView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(contentStackView)

        createConstraints()

        actionButton.addTarget(self, action: #selector(ContactsCell.actionButtonPressed(sender:)), for: .touchUpInside)
    }

    private func configureSubviews() {

        setUp()

        separator.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(separator)

        createSeparatorConstraints()

        separator.backgroundColor = ViewColors.backgroundSeparatorCell

        backgroundColor = ViewColors.backgroundUserCell

        titleLabel.textColor = LabelColors.textDefault
        subtitleLabel.textColor = LabelColors.textCellSubtitle

        updateTitleLabel()
    }

    private func createConstraints() {

        let buttonMargin: CGFloat = 16

        NSLayoutConstraint.activate([
            avatar.widthAnchor.constraint(equalToConstant: 28),
            avatar.heightAnchor.constraint(equalToConstant: 28),
            avatarSpacer.widthAnchor.constraint(equalToConstant: 64),
            avatarSpacer.heightAnchor.constraint(equalTo: avatar.heightAnchor),
            avatarSpacer.centerXAnchor.constraint(equalTo: avatar.centerXAnchor),
            avatarSpacer.centerYAnchor.constraint(equalTo: avatar.centerYAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            contentStackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -buttonMargin)
        ])

        [actionButton, buttonSpacer].prepareForLayout()
        NSLayoutConstraint.activate([
            buttonSpacer.topAnchor.constraint(equalTo: actionButton.topAnchor),
            buttonSpacer.bottomAnchor.constraint(equalTo: actionButton.bottomAnchor),

            actionButton.widthAnchor.constraint(equalToConstant: actionButtonWidth),
            buttonSpacer.trailingAnchor.constraint(equalTo: actionButton.trailingAnchor),
            buttonSpacer.leadingAnchor.constraint(equalTo: actionButton.leadingAnchor, constant: -buttonMargin)
        ])
    }

    func actionButtonWidth(forTitles actionButtonTitles: [String], textTransform: TextTransform, contentInsets: UIEdgeInsets, textAttributes: [NSAttributedString.Key: Any]?) -> Float {
        var width: CGFloat = 0
        for title: String in actionButtonTitles {
            let transformedTitle = title.applying(transform: textTransform)
            let titleWidth = transformedTitle.size(withAttributes: textAttributes).width

            if titleWidth > width {
                width = titleWidth
            }
        }
        return ceilf(Float(contentInsets.left + width + contentInsets.right))
    }

    private func updateTitleLabel() {
        guard let user, let selfUser = ZMUser.selfUser() else {
            return
        }

        titleLabel.attributedText = user.nameIncludingAvailability(color: LabelColors.textDefault, selfUser: selfUser)
    }

    @objc func actionButtonPressed(sender: Any?) {
        if let user = user, let action = action {
            actionButtonHandler?(user, action)
        }
    }
}

extension ContactsCell: UserCellSubtitleProtocol { }

extension ContactsCell {

    typealias ContactsUIActionButton = L10n.Localizable.ContactsUi.ActionButton

    enum Action {

        case open
        case invite

        var localizedDescription: String {
            switch self {
            case .open:
                return ContactsUIActionButton.open.capitalized
            case .invite:
                return ContactsUIActionButton.invite.capitalized
            }
        }
    }
}
