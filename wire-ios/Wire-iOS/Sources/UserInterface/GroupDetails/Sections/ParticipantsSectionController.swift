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
import WireSyncEngine

protocol ParticipantsCellConfigurable: Reusable {
    func configure(with rowType: ParticipantsRowType, conversation: GroupDetailsConversationType, showSeparator: Bool)
}

enum ParticipantsRowType {

    case user(_ user: UserType, _ isE2EICertified: Bool)
    case showAll(Int)

    var cellType: ParticipantsCellConfigurable.Type {
        switch self {
        case .user: return UserCell.self
        case .showAll: return ShowAllParticipantsCell.self
        }
    }
}

enum ConversationRole {
    case admin, member

    var name: String {
        switch self {
        case .admin:
            return "Admins"
        case .member:
            return "Members"
        }
    }
}

private struct ParticipantsSectionViewModel {
    let rows: [ParticipantsRowType]
    let participants: [UserType]
    let conversationRole: ConversationRole
    let userSession: UserSession
    let showSectionCount: Bool
    var sectionAccesibilityIdentifier = "label.groupdetails.participants"

    var sectionTitle: String? {
        typealias GroupDetails = L10n.Localizable.GroupDetails

        switch (conversationRole, showSectionCount) {
        case (.member, true):
            return GroupDetails.ConversationMembersHeader.title.localizedUppercase + " (%d)".localized(args: participants.count)

        case (.member, false):
            return GroupDetails.ConversationMembersHeader.title.localizedUppercase

        case (.admin, true):
            return GroupDetails.ConversationAdminsHeader.title.localizedUppercase + " (%d)".localized(args: participants.count)

        case (.admin, false):
            return GroupDetails.ConversationAdminsHeader.title.localizedUppercase
        }
    }

    var footerTitle: String {
        switch conversationRole {
        case .admin:
            return L10n.Localizable.Participants.Section.Admins.footer
        case .member:
            return L10n.Localizable.Participants.Section.Members.footer
        }
    }

    var footerVisible: Bool {
        return participants.isEmpty
    }

    var accessibilityTitle: String {
        return conversationRole.name
    }

    /// init method
    ///
    /// - Parameters:
    ///   - users: list of conversation participants
    ///   - conversationRole: participants' ConversationRole
    ///   - totalParticipantsCount: the number of all participants in the conversation
    ///   - clipSection: enable/disable the display of the “ShowAll” button
    ///   - maxParticipants: max number of participants we can display
    ///   - maxDisplayedParticipants: max number of participants we can display, if there are more than maxParticipants participants
    ///   - showSectionCount: current view model - a search result or not
    init(
        users: [UserType],
        conversationRole: ConversationRole,
        totalParticipantsCount: Int,
        clipSection: Bool = true,
        maxParticipants: Int,
        maxDisplayedParticipants: Int,
        showSectionCount: Bool = true,
        userSession: UserSession
    ) {
        participants = users.sorted { $0.name < $1.name }
        self.conversationRole = conversationRole
        self.showSectionCount = showSectionCount
        self.userSession = userSession
        rows = clipSection
        ? ParticipantsSectionViewModel.computeRows(
            participants,
            totalParticipantsCount: totalParticipantsCount,
            maxParticipants: maxParticipants,
            maxDisplayedParticipants: maxDisplayedParticipants
        )
        : participants.map { participant in
            .user(participant, false)
        }
    }

    static func computeRows(_ participants: [UserType], totalParticipantsCount: Int, maxParticipants: Int, maxDisplayedParticipants: Int) -> [ParticipantsRowType] {
        guard participants.count > maxParticipants else {
            return participants.map { participant in
                .user(participant, false)
            }
        }
        return participants[0..<maxDisplayedParticipants]
            .map { .user($0, false) } + [.showAll(totalParticipantsCount)]
    }
}

extension UserCell: ParticipantsCellConfigurable {
    func configure(with rowType: ParticipantsRowType, conversation: GroupDetailsConversationType, showSeparator: Bool) {
        guard case let .user(user, isE2EICertified) = rowType else {
            preconditionFailure("expected different 'ParticipantsRowType'!")
        }
        guard let selfUser = SelfUser.provider?.providedSelfUser else {
            assertionFailure("expected available 'user'!")
            return
        }

        configure(
            userStatus: .init(user: user, isCertified: isE2EICertified),
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

final class ParticipantsSectionController: GroupDetailsSectionController {

    fileprivate weak var collectionView: UICollectionView? {
        didSet {
            guard let collectionView =  collectionView else { return }
            SectionFooter.register(collectionView: collectionView)
        }
    }
    private weak var delegate: GroupDetailsSectionControllerDelegate?
    private var viewModel: ParticipantsSectionViewModel
    private let conversation: GroupDetailsConversationType
    private var token: AnyObject?

    init(participants: [UserType],
         conversationRole: ConversationRole,
         conversation: GroupDetailsConversationType,
         delegate: GroupDetailsSectionControllerDelegate,
         totalParticipantsCount: Int,
         clipSection: Bool = true,
         maxParticipants: Int = Int.ConversationParticipants.maxNumberWithoutTruncation,
         maxDisplayedParticipants: Int = Int.ConversationParticipants.maxNumberOfDisplayed,
         showSectionCount: Bool = true,
         userSession: UserSession) {
        viewModel = .init(users: participants,
                          conversationRole: conversationRole,
                          totalParticipantsCount: totalParticipantsCount,
                          clipSection: clipSection,
                          maxParticipants: maxParticipants,
                          maxDisplayedParticipants: maxDisplayedParticipants,
                          showSectionCount: showSectionCount, userSession: userSession)
        self.conversation = conversation
        self.delegate = delegate
        super.init()

        token = userSession.addUserObserver(self)
    }

    override func prepareForUse(in collectionView: UICollectionView?) {
        super.prepareForUse(in: collectionView)
        collectionView?.register(UserCell.self, forCellWithReuseIdentifier: UserCell.reuseIdentifier)
        collectionView?.register(ShowAllParticipantsCell.self, forCellWithReuseIdentifier: ShowAllParticipantsCell.reuseIdentifier)
        self.collectionView = collectionView
    }

    override var sectionTitle: String? {
        return viewModel.sectionTitle
    }

    override var sectionAccessibilityIdentifier: String {
        return viewModel.sectionAccesibilityIdentifier
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.rows.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let configuration = viewModel.rows[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: configuration.cellType.reuseIdentifier, for: indexPath) as! ParticipantsCellConfigurable & UICollectionViewCell
        let showSeparator = (viewModel.rows.count - 1) != indexPath.row
        (cell as? SectionListCellType)?.sectionName = viewModel.accessibilityTitle
        (cell as? SectionListCellType)?.cellIdentifier = "participants.section.participants.cell"
        cell.configure(with: configuration, conversation: conversation, showSeparator: showSeparator)
        return cell
    }

    // MARK: - Footer

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForFooterInSection section: Int) -> CGSize {

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

    override func collectionView(_ collectionView: UICollectionView,
                                 viewForSupplementaryElementOfKind kind: String,
                                 at indexPath: IndexPath) -> UICollectionReusableView {

        guard kind == UICollectionView.elementKindSectionFooter else {
            return super.collectionView(collectionView, viewForSupplementaryElementOfKind: kind, at: indexPath)
        }

        let view = collectionView.dequeueFooter(for: indexPath)
        (view as? SectionFooter)?.titleLabel.text = viewModel.footerTitle

        return view
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch viewModel.rows[indexPath.row] {
        case .user(let user, _):
            delegate?.presentDetails(for: user)
        case .showAll:
            delegate?.presentFullParticipantsList(for: viewModel.participants, in: conversation)
        }
    }

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        switch viewModel.rows[indexPath.row] {
        case .user(let bareUser, _):
            return !bareUser.isSelfUser
        default:
            return true
        }
    }

}

extension ParticipantsSectionController: UserObserving {

    func userDidChange(_ changeInfo: UserChangeInfo) {
        guard changeInfo.connectionStateChanged || changeInfo.nameChanged else { return }
        collectionView?.reloadData()
    }

}

private extension UICollectionView {

    func dequeueFooter(for indexPath: IndexPath) -> UICollectionReusableView {
        dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter,
                                         withReuseIdentifier: "SectionFooter",
                                         for: indexPath)
    }

}
