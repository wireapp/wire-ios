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

// MARK: - ParticipantsRowType

enum ParticipantsRowType {
    case user(UserType)
    case showAll(_ totalParticipantsCount: Int)

    // MARK: Internal

    var cellType: UICollectionViewCell.Type {
        switch self {
        case .user:
            UserCell.self
        case .showAll:
            ShowAllParticipantsCell.self
        }
    }
}

// MARK: - ConversationRole

enum ConversationRole {
    case admin
    case member

    // MARK: Internal

    var name: String {
        switch self {
        case .admin:
            "Admins"
        case .member:
            "Members"
        }
    }
}

// MARK: - ParticipantsSectionViewModel

private struct ParticipantsSectionViewModel {
    // MARK: Lifecycle

    /// init method
    ///
    /// - Parameters:
    ///   - users: list of conversation participants
    ///   - userStatuses: additional status info like the E2EI certification status.
    ///   - conversationRole: participants' ConversationRole
    ///   - totalParticipantsCount: the number of all participants in the conversation
    ///   - clipSection: enable/disable the display of the “ShowAll” button
    ///   - maxParticipants: max number of participants we can display
    ///   - maxDisplayedParticipants: max number of participants we can display, if there are more than maxParticipants
    /// participants
    ///   - showSectionCount: current view model - a search result or not
    init(
        users: [UserType],
        userStatuses: [UUID: UserStatus],
        conversationRole: ConversationRole,
        totalParticipantsCount: Int,
        clipSection: Bool = true,
        maxParticipants: Int,
        maxDisplayedParticipants: Int,
        showSectionCount: Bool = true,
        userSession: UserSession
    ) {
        self.participants = users.sortedAscendingPrependingNil(by: \.name)
        self.userStatuses = userStatuses
        self.conversationRole = conversationRole
        self.showSectionCount = showSectionCount
        self.userSession = userSession
        self.rows = clipSection
            ? ParticipantsSectionViewModel.computeRows(
                participants,
                totalParticipantsCount: totalParticipantsCount,
                maxParticipants: maxParticipants,
                maxDisplayedParticipants: maxDisplayedParticipants
            )
            : participants.map { participant in
                .user(participant)
            }
    }

    // MARK: Internal

    let rows: [ParticipantsRowType]
    let participants: [UserType]
    let userStatuses: [UUID: UserStatus]
    let conversationRole: ConversationRole
    let userSession: UserSession
    let showSectionCount: Bool
    var sectionAccesibilityIdentifier = "label.groupdetails.participants"

    var sectionTitle: String? {
        typealias GroupDetails = L10n.Localizable.GroupDetails

        switch (conversationRole, showSectionCount) {
        case (.member, true):
            return GroupDetails.ConversationMembersHeader.title.localizedUppercase + " (%d)"
                .localized(args: participants.count)

        case (.member, false):
            return GroupDetails.ConversationMembersHeader.title.localizedUppercase

        case (.admin, true):
            return GroupDetails.ConversationAdminsHeader.title.localizedUppercase + " (%d)"
                .localized(args: participants.count)

        case (.admin, false):
            return GroupDetails.ConversationAdminsHeader.title.localizedUppercase
        }
    }

    var footerTitle: String {
        switch conversationRole {
        case .admin:
            L10n.Localizable.Participants.Section.Admins.footer
        case .member:
            L10n.Localizable.Participants.Section.Members.footer
        }
    }

    var footerVisible: Bool {
        participants.isEmpty
    }

    var accessibilityTitle: String {
        conversationRole.name
    }

    static func computeRows(
        _ participants: [UserType],
        totalParticipantsCount: Int,
        maxParticipants: Int,
        maxDisplayedParticipants: Int
    ) -> [ParticipantsRowType] {
        guard participants.count > maxParticipants else {
            return participants.map(ParticipantsRowType.user)
        }
        return participants[0 ..< maxDisplayedParticipants]
            .map(ParticipantsRowType.user) + [.showAll(totalParticipantsCount)]
    }
}

extension UserCell {
    func configure(
        user: UserType,
        isE2EICertified: Bool,
        conversation: GroupDetailsConversationType,
        showSeparator: Bool
    ) {
        guard let selfUser = SelfUser.provider?.providedSelfUser else {
            assertionFailure("expected available 'user'!")
            return
        }

        configure(
            userStatus: .init(user: user, isE2EICertified: isE2EICertified),
            user: user,
            userIsSelfUser: user.isSelfUser,
            isSelfUserPartOfATeam: selfUser.hasTeam,
            conversation: conversation as? ZMConversation
        )
        accessoryIconView.isHidden = user.isSelfUser
        accessibilityIdentifier = identifier
        accessibilityHint = L10n.Accessibility.ConversationDetails.ParticipantCell.hint
        self.showSeparator = showSeparator
    }
}

// MARK: - ParticipantsSectionController

final class ParticipantsSectionController: GroupDetailsSectionController {
    // MARK: Lifecycle

    init(
        participants: [UserType],
        userStatuses: [UUID: UserStatus],
        conversationRole: ConversationRole,
        conversation: GroupDetailsConversationType,
        delegate: GroupDetailsSectionControllerDelegate,
        totalParticipantsCount: Int,
        clipSection: Bool = true,
        maxParticipants: Int = .ConversationParticipants.maxNumberWithoutTruncation,
        maxDisplayedParticipants: Int = .ConversationParticipants.maxNumberOfDisplayed,
        showSectionCount: Bool = true,
        userSession: UserSession
    ) {
        self.viewModel = .init(
            users: participants,
            userStatuses: userStatuses,
            conversationRole: conversationRole,
            totalParticipantsCount: totalParticipantsCount,
            clipSection: clipSection,
            maxParticipants: maxParticipants,
            maxDisplayedParticipants: maxDisplayedParticipants,
            showSectionCount: showSectionCount,
            userSession: userSession
        )
        self.conversation = conversation
        self.delegate = delegate
        super.init()

        self.token = userSession.addUserObserver(self)
    }

    // MARK: Internal

    override var sectionTitle: String? {
        viewModel.sectionTitle
    }

    override var sectionAccessibilityIdentifier: String {
        viewModel.sectionAccesibilityIdentifier
    }

    override func prepareForUse(in collectionView: UICollectionView?) {
        super.prepareForUse(in: collectionView)
        collectionView?.register(UserCell.self, forCellWithReuseIdentifier: UserCell.reuseIdentifier)
        collectionView?.register(
            ShowAllParticipantsCell.self,
            forCellWithReuseIdentifier: ShowAllParticipantsCell.reuseIdentifier
        )
        self.collectionView = collectionView
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.rows.count
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let configuration = viewModel.rows[indexPath.row]
        let showSeparator = (viewModel.rows.count - 1) != indexPath.row

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: configuration.cellType.reuseIdentifier,
            for: indexPath
        )
        if let cell = cell as? SectionListCellType {
            cell.sectionName = viewModel.accessibilityTitle
            cell.cellIdentifier = "participants.section.participants.cell"
        }

        let unexpectedCellHandler: () -> UICollectionViewCell = {
            let message = "Unexpected collection view cell type: \(String(describing: cell.self))"
            WireLogger.conversation.error(message)
            assertionFailure(message)
            return cell
        }

        switch configuration {
        case let .user(user):
            guard let cell = cell as? UserCell else {
                return unexpectedCellHandler()
            }
            let isE2EICertified =
                if let userID = user.remoteIdentifier,
                let userStatus = viewModel.userStatuses[userID] {
                    userStatus.isE2EICertified
                } else {
                    false
                }
            cell.configure(
                user: user,
                isE2EICertified: isE2EICertified,
                conversation: conversation,
                showSeparator: showSeparator
            )

        case let .showAll(totalParticipantsCount):
            guard let cell = cell as? ShowAllParticipantsCell else {
                return unexpectedCellHandler()
            }
            cell.configure(
                totalParticipantsCount: totalParticipantsCount,
                conversation: conversation,
                showSeparator: showSeparator
            )
        }

        return cell
    }

    // MARK: - Footer

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForFooterInSection section: Int
    ) -> CGSize {
        guard
            viewModel.footerVisible,
            let footer = collectionView.dequeueFooter(for: IndexPath(item: 0, section: section)) as? SectionFooter
        else {
            return .zero
        }

        footer.titleLabel.text = viewModel.footerTitle
        footer.size(fittingWidth: collectionView.bounds.width)

        return footer.bounds.size
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionFooter else {
            return super.collectionView(collectionView, viewForSupplementaryElementOfKind: kind, at: indexPath)
        }

        let view = collectionView.dequeueFooter(for: indexPath)
        (view as? SectionFooter)?.titleLabel.text = viewModel.footerTitle

        return view
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch viewModel.rows[indexPath.row] {
        case let .user(user):
            delegate?.presentDetails(for: user)
        case .showAll:
            delegate?.presentFullParticipantsList(for: viewModel.participants, in: conversation)
        }
    }

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        switch viewModel.rows[indexPath.row] {
        case let .user(bareUser):
            !bareUser.isSelfUser
        default:
            true
        }
    }

    // MARK: Fileprivate

    fileprivate weak var collectionView: UICollectionView? {
        didSet {
            guard let collectionView else {
                return
            }
            SectionFooter.register(collectionView: collectionView)
        }
    }

    // MARK: Private

    private weak var delegate: GroupDetailsSectionControllerDelegate?
    private var viewModel: ParticipantsSectionViewModel
    private let conversation: GroupDetailsConversationType
    private var token: NSObjectProtocol?
}

// MARK: UserObserving

extension ParticipantsSectionController: UserObserving {
    func userDidChange(_ changeInfo: UserChangeInfo) {
        guard changeInfo.connectionStateChanged || changeInfo.nameChanged else {
            return
        }
        collectionView?.reloadData()
    }
}

extension UICollectionView {
    fileprivate func dequeueFooter(for indexPath: IndexPath) -> UICollectionReusableView {
        dequeueReusableSupplementaryView(
            ofKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: "SectionFooter",
            for: indexPath
        )
    }
}
