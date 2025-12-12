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

import Foundation
import WireDataModel

protocol GroupOptionsSectionControllerDelegate: AnyObject {
    func presentTimeoutOptions(animated: Bool)
    func presentGuestOptions(animated: Bool)
    func presentServicesOptions(animated: Bool)
    func presentNotificationsOptions(animated: Bool)
    func presentAccessOptions(animated: Bool)
    func presentChannelHistoryOptions(animated: Bool)
}

final class GroupOptionsSectionController: GroupDetailsSectionController {

    enum Option: Int, CaseIterable {

        case channelAccess = 0
        case channelHistoryDepth
        case notifications
        case guests
        case services
        case timeout
        case fileCollaboration // keep at the last position

        func accessible(
            in conversation: GroupDetailsConversationType,
            by user: UserType
        ) -> Bool {
            switch self {
            case .channelAccess: user.canModifyChannelAccessLevelSettings(in: conversation)
            case .notifications: user.canModifyNotificationSettings(in: conversation)
            case .fileCollaboration: conversation.isCellsEnabled
            case .guests:        user.canModifyGuestsAccessControlSettings(in: conversation)
            case .services:      user.canModifyGuestsAccessControlSettings(in: conversation) && conversation
                .botCanBeAdded
            case .timeout:       user.canModifyEphemeralSettings(in: conversation) && !conversation.isCellsEnabled
            case .channelHistoryDepth:
                if DeveloperFlag.channelsHistory.isOn {
                    user.canModifyChannelHistoryDepthSettings(in: conversation)
                } else {
                    false
                }
            }
        }

        var cellReuseIdentifier: String {
            switch self {
            case .guests: GroupDetailsGuestOptionsCell.zm_reuseIdentifier
            case .services: GroupDetailsServicesCell.zm_reuseIdentifier
            case .timeout: GroupDetailsTimeoutOptionsCell.zm_reuseIdentifier
            case .notifications: GroupDetailsNotificationOptionsCell.zm_reuseIdentifier
            case .fileCollaboration: GroupDetailsFileCollaborationCell.zm_reuseIdentifier
            case .channelAccess: GroupDetailsAccessOptionsCell.zm_reuseIdentifier
            case .channelHistoryDepth: GroupDetailsChannelHistoryOptionsCell.zm_reuseIdentifier
            }
        }

    }

    // MARK: - Properties

    private weak var delegate: GroupOptionsSectionControllerDelegate?
    private let conversation: GroupDetailsConversationType
    private let syncCompleted: Bool
    private let options: [Option]
    private var footerView = SectionFooter(frame: .zero)

    var hasOptions: Bool {
        !options.isEmpty
    }

    init(
        conversation: GroupDetailsConversationType,
        user: UserType,
        delegate: GroupOptionsSectionControllerDelegate,
        syncCompleted: Bool
    ) {
        self.delegate = delegate
        self.conversation = conversation
        self.syncCompleted = syncCompleted
        self.options = Option.allCases.filter { $0.accessible(in: conversation, by: user) }
    }

    // MARK: - Collection View

    override var sectionTitle: String {
        L10n.Localizable.Participants.Section.settings.localizedUppercase
    }

    override func prepareForUse(in collectionView: UICollectionView?) {
        super.prepareForUse(in: collectionView)
        collectionView.flatMap(GroupDetailsGuestOptionsCell.register)
        collectionView.flatMap(GroupDetailsServicesCell.register)
        collectionView.flatMap(GroupDetailsTimeoutOptionsCell.register)
        collectionView.flatMap(GroupDetailsNotificationOptionsCell.register)
        collectionView.flatMap(GroupDetailsAccessOptionsCell.register)
        collectionView.flatMap(GroupDetailsChannelHistoryOptionsCell.register)
        collectionView.flatMap(GroupDetailsFileCollaborationCell.register)
        collectionView.flatMap(SectionFooter.register)
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        options.count
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        CGSize(width: collectionView.bounds.size.width, height: 56)
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let option = options[indexPath.row]
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: option.cellReuseIdentifier,
            for: indexPath
        ) as! GroupDetailsDisclosureOptionsCell

        cell.configure(with: conversation)
        cell.showSeparator = indexPath.row < options.count - 1
        cell.isUserInteractionEnabled = syncCompleted
        cell.alpha = syncCompleted ? 1 : 0.48
        return cell

    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        switch options[indexPath.row] {
        case .guests:
            delegate?.presentGuestOptions(animated: true)
        case .services:
            delegate?.presentServicesOptions(animated: true)
        case .timeout:
            if !conversation.isCellsEnabled {
                delegate?.presentTimeoutOptions(animated: true)
            }
        case .notifications:
            delegate?.presentNotificationsOptions(animated: true)
        case .channelAccess:
            delegate?.presentAccessOptions(animated: true)
        case .channelHistoryDepth:
            delegate?.presentChannelHistoryOptions(animated: true)
        case .fileCollaboration:
            break // no op
        }

    }

    // MARK: - Footer

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForFooterInSection section: Int
    ) -> CGSize {

        guard conversation.isCellsEnabled else {
            return .zero
        }

        footerView.titleLabel.text = L10n.Localizable.GroupDetails.FileCollaborationCell.footer
        footerView.size(fittingWidth: collectionView.bounds.width)
        return footerView.bounds.size
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionFooter else {
            return super.collectionView(
                collectionView,
                viewForSupplementaryElementOfKind: kind,
                at: indexPath
            )
        }

        let view = collectionView.dequeueReusableSupplementaryView(
            ofKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: SectionFooter.reuseIdentifier,
            for: indexPath
        ) as! SectionFooter

        view.titleLabel.text = conversation.isCellsEnabled ? L10n.Localizable.GroupDetails.FileCollaborationCell
            .footer : nil

        return view

    }

}
