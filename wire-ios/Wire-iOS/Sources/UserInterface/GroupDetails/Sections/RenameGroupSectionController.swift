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

// MARK: - RenameGroupSectionController

final class RenameGroupSectionController: NSObject, CollectionViewSectionController {
    // MARK: Lifecycle

    init(conversation: GroupDetailsConversationType, userSession: UserSession) {
        self.conversation = conversation
        self.userSession = userSession
        super.init()

        if let conversation = conversation as? ZMConversation {
            self.token = ConversationChangeInfo.add(observer: self, for: conversation)
        }
    }

    // MARK: Internal

    let userSession: UserSession

    var isHidden: Bool {
        false
    }

    func focus() {
        guard conversation.isSelfAnActiveMember else { return }
        renameCell?.titleTextField.becomeFirstResponder()
    }

    func prepareForUse(in collectionView: UICollectionView?) {
        collectionView.flatMap(GroupDetailsRenameCell.register)
        collectionView?.register(
            SectionFooter.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: "SectionFooter"
        )
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        1
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(ofType: GroupDetailsRenameCell.self, for: indexPath)

        if let user = SelfUser.provider?.providedSelfUser {
            cell.configure(for: conversation, editable: user.canModifyTitle(in: conversation))
        } else {
            assertionFailure("expected available 'user'!")
        }

        cell.titleTextField.textFieldDelegate = self
        renameCell = cell
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        let view = collectionView.dequeueReusableSupplementaryView(
            ofKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: "SectionFooter",
            for: indexPath
        )
        (view as? SectionFooter)?.titleLabel.text = L10n.Localizable.Participants.Section.Name
            .footer(ZMConversation.maxParticipants)
        return view
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        CGSize(width: collectionView.bounds.size.width, height: 56)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForFooterInSection section: Int
    ) -> CGSize {
        guard
            let user = SelfUser.provider?.providedSelfUser,
            user.hasTeam
        else { return .zero }

        sizingFooter.titleLabel.text = L10n.Localizable.Participants.Section.Name.footer(ZMConversation.maxParticipants)
        sizingFooter.size(fittingWidth: collectionView.bounds.width)
        return sizingFooter.bounds.size
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        focus()
    }

    // MARK: Private

    private var validName: String?
    private var conversation: GroupDetailsConversationType
    private var renameCell: GroupDetailsRenameCell?
    private var token: AnyObject?
    private var sizingFooter = SectionFooter(frame: .zero)
}

// MARK: ZMConversationObserver

extension RenameGroupSectionController: ZMConversationObserver {
    func conversationDidChange(_ changeInfo: ConversationChangeInfo) {
        guard changeInfo.securityLevelChanged || changeInfo.nameChanged else { return }

        guard let conversation = conversation as? ZMConversation else { return }

        renameCell?.configure(for: conversation, editable: ZMUser.selfUser()?.canModifyTitle(in: conversation) ?? false)
    }
}

// MARK: SimpleTextFieldDelegate

extension RenameGroupSectionController: SimpleTextFieldDelegate {
    func textFieldReturnPressed(_ textField: SimpleTextField) {
        guard let value = textField.value else { return }

        switch  value {
        case let .valid(name):
            validName = name
            textField.endEditing(true)

        case .error:
            // TODO: show error
            textField.endEditing(true)
        }
    }

    func textField(_ textField: SimpleTextField, valueChanged value: SimpleTextField.Value) {}

    func textFieldDidBeginEditing(_: SimpleTextField) {
        renameCell?.accessoryIconView.isHidden = true
    }

    func textFieldDidEndEditing(_ textField: SimpleTextField) {
        if let newName = validName {
            userSession.enqueue {
                self.conversation.userDefinedName = newName
            }
        } else {
            textField.text = conversation.displayName
        }

        renameCell?.accessoryIconView.isHidden = false
    }
}
