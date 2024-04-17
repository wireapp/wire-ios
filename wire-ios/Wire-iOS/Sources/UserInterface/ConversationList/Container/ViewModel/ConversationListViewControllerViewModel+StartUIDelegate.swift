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
import WireDataModel
import UIKit
import WireSyncEngine

extension ConversationListViewController.ViewModel: StartUIDelegate {
    func startUI(_ startUI: StartUIViewController, didSelect user: UserType) {
        guard let userID = user.qualifiedID else { return }

        let conversation = user.oneToOneConversation

        Task {
            do {
                let status = try await userSession.oneOnOneConversationCreationStatus.invoke(userID: userID)

                switch status {
                case .exists(protocol: .proteus, established: _),
                        .exists(protocol: .mls, established: true):

                    guard let conversation else { return }
                    await openConversation(conversation)

                case .exists(protocol: .mls, established: false), 
                        .doesNotExist(protocol: .mls):

                    await openUserProfile(user)

                case .doesNotExist(protocol: .proteus):

                    await MainActor.run { [weak self] in
                        self?.createTeamOneOnOne(user) { result in
                            guard case .success(let conversation) = result else { return }
                            self?.openConversation(conversation)
                        }
                    }

                default:
                    break
                }

            } catch {

            }
        }
    }

    func startUI(_ startUI: StartUIViewController, didSelect conversation: ZMConversation) {
        startUI.dismissIfNeeded(animated: true) {
            ZClientViewController.shared?.select(conversation: conversation, focusOnView: true, animated: true)
        }
    }

    @MainActor
    func openConversation(_ conversation: ZMConversation) {
        ZClientViewController.shared?.select(conversation: conversation, focusOnView: true, animated: true)
    }

    @MainActor
    func openUserProfile(_ user: UserType) {
        let profileViewController = ProfileViewController(
            user: user,
            viewer: selfUser,
            context: .profileViewer,
            userSession: userSession
        )
        profileViewController.delegate = self

        let navigationController = profileViewController.wrapInNavigationController(setBackgroundColor: true)
        navigationController.modalPresentationStyle = .formSheet

        ZClientViewController.shared?.present(navigationController, animated: true)
    }

    private func createTeamOneOnOne(
        _ user: UserType,
        callback onConversationCreated: @escaping ConversationCreatedBlock
    ) {
        guard let userSession = ZMUserSession.shared() else {
            return
        }

        viewController?.setState(.conversationList, animated: true) {
            userSession.createTeamOneOnOne(with: user) {
                switch $0 {
                case .success(let conversation):
                    onConversationCreated(.success(conversation))

                case .failure(let error):
                    onConversationCreated(.failure(error))
                }
            }
        }
    }

}

extension ConversationListViewController.ViewModel: ProfileViewControllerDelegate {

    func profileViewController(_ controller: ProfileViewController?, wantsToNavigateTo conversation: ZMConversation) {

        controller?.dismiss(animated: true) {
            ZClientViewController.shared?.select(
                conversation: conversation,
                focusOnView: true,
                animated: true
            )
        }
    }

}
