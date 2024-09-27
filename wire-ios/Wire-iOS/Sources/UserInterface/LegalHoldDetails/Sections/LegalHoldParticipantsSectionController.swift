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

import Foundation
import WireSyncEngine

// MARK: - LegalHoldParticipantsSectionViewModel

private struct LegalHoldParticipantsSectionViewModel {
    // MARK: Lifecycle

    init(participants: [UserType]) {
        self.participants = participants
    }

    // MARK: Internal

    let participants: [UserType]

    var sectionAccesibilityIdentifier = "label.groupdetails.participants"

    var sectionTitle: String {
        L10n.Localizable.Legalhold.Participants.Section.title(participants.count).localizedUppercase
    }
}

// MARK: - LegalHoldParticipantsSectionControllerDelegate

protocol LegalHoldParticipantsSectionControllerDelegate: AnyObject {
    func legalHoldParticipantsSectionWantsToPresentUserProfile(for user: UserType)
}

typealias LegalHoldDetailsConversation = Conversation & GroupDetailsConversation

extension ConversationLike {
    fileprivate func createViewModel() -> LegalHoldParticipantsSectionViewModel {
        LegalHoldParticipantsSectionViewModel(
            participants: sortedActiveParticipantsUserTypes
                .filter(\.isUnderLegalHold)
        )
    }
}

// MARK: - LegalHoldParticipantsSectionController

final class LegalHoldParticipantsSectionController: GroupDetailsSectionController {
    // MARK: Lifecycle

    init(conversation: LegalHoldDetailsConversation) {
        self.viewModel = conversation.createViewModel()
        self.conversation = conversation
        super.init()

        if let userSession = ZMUserSession.shared() {
            self.token = UserChangeInfo.add(userObserver: self, in: userSession)
        }
    }

    // MARK: Internal

    weak var delegate: LegalHoldParticipantsSectionControllerDelegate?

    override var sectionTitle: String {
        viewModel.sectionTitle
    }

    override var sectionAccessibilityIdentifier: String {
        viewModel.sectionAccesibilityIdentifier
    }

    override func prepareForUse(in collectionView: UICollectionView?) {
        super.prepareForUse(in: collectionView)
        collectionView?.register(UserCell.self, forCellWithReuseIdentifier: UserCell.reuseIdentifier)
        self.collectionView = collectionView
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.participants.count
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let participant = viewModel.participants[indexPath.row]
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: UserCell.reuseIdentifier,
            for: indexPath
        ) as! UserCell
        let showSeparator = (viewModel.participants.count - 1) != indexPath.row

        if let selfUser = SelfUser.provider?.providedSelfUser {
            cell.configure(
                user: participant,
                isSelfUserPartOfATeam: selfUser.hasTeam,
                conversation: conversation
            )
        } else {
            assertionFailure("expected available 'user'!")
        }

        cell.accessoryIconView.isHidden = false
        cell.accessibilityIdentifier = "participants.section.participants.cell"
        cell.showSeparator = showSeparator

        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let user = viewModel.participants[indexPath.row]

        delegate?.legalHoldParticipantsSectionWantsToPresentUserProfile(for: user)
    }

    // MARK: Fileprivate

    fileprivate weak var collectionView: UICollectionView?

    // MARK: Private

    private var viewModel: LegalHoldParticipantsSectionViewModel
    private let conversation: LegalHoldDetailsConversation
    private var token: AnyObject?
}

// MARK: UserObserving

extension LegalHoldParticipantsSectionController: UserObserving {
    func userDidChange(_ changeInfo: UserChangeInfo) {
        guard changeInfo.connectionStateChanged || changeInfo.nameChanged || changeInfo.isUnderLegalHoldChanged
        else {
            return
        }

        viewModel = conversation.createViewModel()
        collectionView?.reloadData()
    }
}
