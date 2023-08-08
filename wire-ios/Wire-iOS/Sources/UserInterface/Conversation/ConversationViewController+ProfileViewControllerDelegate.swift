//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

import WireSyncEngine

extension ConversationViewController {
    func createUserDetailViewController() -> UIViewController {
        guard let user = (conversation.firstActiveParticipantOtherThanSelf ?? conversation.connectedUser) else {
            fatal("no firstActiveParticipantOtherThanSelf!")
        }

        return UserDetailViewControllerFactory.createUserDetailViewController(user: user, conversation: conversation, profileViewControllerDelegate: self, viewControllerDismisser: self)
    }
}

extension ConversationViewController: ProfileViewControllerDelegate {
    func profileViewController(_ controller: ProfileViewController?, wantsToNavigateTo conversation: ZMConversation) {
        dismiss(animated: true) {
            self.zClientViewController.select(conversation: conversation, focusOnView: true, animated: true)
        }
    }

    func profileViewController(
        _ controller: ProfileViewController?,
        wantsToCreateConversationWithName name: String?,
        users: UserSet
    ) {
        guard let userSession = ZMUserSession.shared() else { return }

        let conversationCreation: () -> Void = { [weak self] in
            let service = ConversationService(context: userSession.viewContext)
            let users = Set(users.materialize(in: userSession.viewContext))

            service.createGroupConversation(
                name: name,
                users: users,
                allowGuests: true,
                allowServices: true,
                enableReceipts: false,
                messageProtocol: .proteus
            ) {
                switch $0 {
                case .success(let conversation):
                    self?.zClientViewController.select(
                        conversation: conversation,
                        focusOnView: true,
                        animated: true
                    )

                case .failure:
                    // TODO: [John] Handle
                    fatalError("not implemented")
                }
            }
        }

        if nil != presentedViewController {
            dismiss(animated: true, completion: conversationCreation)
        } else {
            conversationCreation()
        }
    }
}
