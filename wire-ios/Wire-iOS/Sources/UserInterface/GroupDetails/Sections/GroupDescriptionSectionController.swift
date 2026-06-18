//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

final class GroupDescriptionSectionController: GroupDetailsSectionController {

    private var conversation: GroupDetailsConversationType
    private var descriptionCell: GroupDetailsDescriptionCell?
    private var token: AnyObject?
    private weak var collectionView: UICollectionView?
    private var currentDescription: String?
    let userSession: UserSession

    override var isHidden: Bool {
        false
    }

    override var sectionTitle: String {
        L10n.Localizable.Participants.Section.Description.title.localizedUppercase
    }

    init(conversation: GroupDetailsConversationType, userSession: UserSession) {
        self.conversation = conversation
        self.userSession = userSession
        self.currentDescription = conversation.groupDescription
        super.init()

        if let conversation = conversation as? ZMConversation {
            self.token = ConversationChangeInfo.add(observer: self, for: conversation)
        }
    }

    override func prepareForUse(in collectionView: UICollectionView?) {
        super.prepareForUse(in: collectionView)
        self.collectionView = collectionView
        collectionView.flatMap(GroupDetailsDescriptionCell.register)
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        1
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(ofType: GroupDetailsDescriptionCell.self, for: indexPath)

        if let user = SelfUser.provider?.providedSelfUser {
            cell.configure(for: conversation, editable: user.canModifyTitle(in: conversation))
        } else {
            assertionFailure("expected available 'user'!")
        }

        cell.descriptionTextView.delegate = self
        descriptionCell = cell
        return cell
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let height = GroupDetailsDescriptionCell.preferredHeight(
            for: currentDescription,
            width: collectionView.bounds.width
        )
        return CGSize(width: collectionView.bounds.width, height: height)
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard conversation.isSelfAnActiveMember else { return }
        descriptionCell?.descriptionTextView.becomeFirstResponder()
    }

}

extension GroupDescriptionSectionController: ZMConversationObserver {

    func conversationDidChange(_ changeInfo: ConversationChangeInfo) {
        guard changeInfo.securityLevelChanged || changeInfo.nameChanged else { return }

        guard let conversation = conversation as? ZMConversation else { return }

        currentDescription = conversation.groupDescription
        descriptionCell?.configure(
            for: conversation,
            editable: ZMUser.selfUser()?.canModifyTitle(in: conversation) ?? false
        )
    }

}

extension GroupDescriptionSectionController: UITextViewDelegate {

    func textViewDidBeginEditing(_ textView: UITextView) {
        descriptionCell?.accessoryIconView.isHidden = true
    }

    func textViewDidChange(_ textView: UITextView) {
        descriptionCell?.updatePlaceholderVisibility()
        currentDescription = textView.text?.isEmpty == false ? textView.text : nil
        collectionView?.collectionViewLayout.invalidateLayout()
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        let newDescription = textView.text?.isEmpty == false ? textView.text : nil
        
        
        Task {
            try await userSession.clientSessionComponent?.updateConversationDescriptionUsecase
                .invoke(
                    description: newDescription ?? "",
                    conversationObjectID: self.conversation.objectId as! NSManagedObjectID
                )
        }
//        userSession.enqueue {
//            
//            )
//            self.conversation.groupDescription = newDescription
//        }
        descriptionCell?.accessoryIconView.isHidden = false
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return true
    }

}
