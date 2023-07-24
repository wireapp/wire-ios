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

    func profileViewController(_ controller: ProfileViewController?,
                               wantsToCreateConversationWithName name: String?,
                               users: UserSet,
                               onCompletion: @escaping (_ postCompletionAction: @escaping () -> Void) -> Void
        ) {
        guard let coordinator = conversationCreationCoordinator else { return }
        let initialized = coordinator.initialize { [weak self] result in
            onCompletion { [weak self] in
                switch result {
                case .success(let conversation):
                    let openConversation = { [weak self] in
                        self?.zClientViewController.select(conversation: conversation,
                                                           focusOnView: true,
                                                           animated: true)
                        return
                    }
                    if nil != self?.presentedViewController {
                        self?.dismiss(animated: true, completion: openConversation)
                    } else {
                        openConversation()
                    }
                case .failure:
                    self?.presentedViewController?.dismiss(animated: true)
                }
                self?.conversationCreationCoordinator?.finalize()
            }
        }
        guard initialized else { return }
        let creatingConversation = coordinator.createConversation(withParticipants: users, name: name)
        guard creatingConversation else {
            coordinator.finalize()
            return
        }
    }
}
