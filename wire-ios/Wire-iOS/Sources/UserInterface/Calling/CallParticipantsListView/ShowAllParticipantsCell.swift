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

import Foundation
import UIKit
import WireDataModel
import WireCommonComponents

class ShowAllParticipantsCell: UICollectionViewCell, SectionListCellType {
    typealias Participants = L10n.Localizable.Call.Participants

    let participantIconView = UIImageView()
    let titleLabel = UILabel()
    let accessoryIconView = UIImageView()
    var contentStackView: UIStackView!

    var sectionName: String?
    var cellIdentifier: String?

    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted
            ? SemanticColors.View.backgroundUserCellHightLighted
            : SemanticColors.View.backgroundUserCell
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init?(coder aDecoder: NSCoder) is not implemented")
    }

    fileprivate func setup() {

        backgroundColor = SemanticColors.View.backgroundUserCell
        participantIconView.translatesAutoresizingMaskIntoConstraints = false
        participantIconView.contentMode = .scaleAspectFit
        participantIconView.setContentHuggingPriority(UILayoutPriority.required, for: .horizontal)

        accessoryIconView.translatesAutoresizingMaskIntoConstraints = false
        accessoryIconView.contentMode = .center

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = FontSpec.init(.normal, .light).font!

        let avatarSpacer = UIView()
        avatarSpacer.addSubview(participantIconView)
        avatarSpacer.translatesAutoresizingMaskIntoConstraints = false
        avatarSpacer.widthAnchor.constraint(equalToConstant: 64).isActive = true
        avatarSpacer.heightAnchor.constraint(equalTo: participantIconView.heightAnchor).isActive = true
        avatarSpacer.centerXAnchor.constraint(equalTo: participantIconView.centerXAnchor).isActive = true
        avatarSpacer.centerYAnchor.constraint(equalTo: participantIconView.centerYAnchor).isActive = true

        let iconViewSpacer = UIView()
        iconViewSpacer.translatesAutoresizingMaskIntoConstraints = false
        iconViewSpacer.widthAnchor.constraint(equalToConstant: 8).isActive = true

        contentStackView = UIStackView(arrangedSubviews: [avatarSpacer, titleLabel, iconViewSpacer, accessoryIconView])
        contentStackView.axis = .horizontal
        contentStackView.distribution = .fill
        contentStackView.alignment = .center
        contentStackView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(contentStackView)
        contentStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        contentStackView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        contentStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        contentStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16).isActive = true

        configureColors()
    }

    private func configureColors() {
        let sectionTextColor = SemanticColors.Icon.foregroundDefault
        backgroundColor = .clear

        participantIconView.setTemplateIcon(.person, size: .tiny)
        participantIconView.tintColor = SemanticColors.Icon.foregroundDefault

        accessoryIconView.setTemplateIcon(.disclosureIndicator, size: 12)
        accessoryIconView.tintColor = sectionTextColor

        titleLabel.textColor = SemanticColors.Label.textDefault
    }

    private func setupAccessibility(with rowType: ParticipantsRowType) {
        isAccessibilityElement = true
        accessibilityIdentifier = identifier

        guard case let .showAll(count) = rowType else {
            return
        }
        accessibilityTraits = .button
        accessibilityLabel = Participants.showAll(count)
        accessibilityHint = L10n.Accessibility.ConversationDetails.ShowParticipantsButton.hint
    }

}

extension ShowAllParticipantsCell: CallParticipantsListCellConfigurable {
    func configure(with configuration: CallParticipantsListCellConfiguration,
                   selfUser: UserType) {
        guard case let .showAll(totalCount: totalCount) = configuration else { preconditionFailure() }

        titleLabel.text = Participants.showAll(totalCount)
    }
}

extension ShowAllParticipantsCell: ParticipantsCellConfigurable {
    func configure(with rowType: ParticipantsRowType, conversation: GroupDetailsConversationType, showSeparator: Bool) {
        guard case let .showAll(count) = rowType else { preconditionFailure() }
        titleLabel.text = Participants.showAll(count)
        cellIdentifier = "cell.call.show_all_participants"
        setupAccessibility(with: rowType)
    }
}
