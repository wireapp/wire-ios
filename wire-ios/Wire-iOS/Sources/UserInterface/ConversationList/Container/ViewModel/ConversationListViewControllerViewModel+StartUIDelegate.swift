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

import Foundation
import WireDataModel
import UIKit
import WireSyncEngine

extension ConversationListViewController.ViewModel: StartUIDelegate {
    func startUI(_ startUI: StartUIViewController, didSelect user: UserType) {
        oneToOneConversationWithUser(user, callback: { conversation in
            guard let conversation = conversation else { return }

            ZClientViewController.shared?.select(conversation: conversation, focusOnView: true, animated: true)
        })
    }

    func startUI(_ startUI: StartUIViewController, didSelect conversation: ZMConversation) {
        startUI.dismissIfNeeded(animated: true) {
            ZClientViewController.shared?.select(conversation: conversation, focusOnView: true, animated: true)
        }
    }

    /// Create a new conversation or open existing 1-to-1 conversation
    ///
    /// - Parameters:
    ///   - user: the user which we want to have a 1-to-1 conversation with
    ///   - onConversationCreated: a block that receives the created conversation
    private func oneToOneConversationWithUser(
        _ user: UserType,
        callback onConversationCreated: @escaping (ZMConversation?) -> Void
    ) {
        guard let userSession = ZMUserSession.shared() else { return }

        viewController?.setState(.conversationList, animated: true) {
            if let conversation = user.oneToOneConversation {
                onConversationCreated(conversation)
            } else {
                userSession.createTeamOneOnOneConversationUseCase().invoke(user: user) {
                    switch $0 {
                    case .success(let conversation):
                        onConversationCreated(conversation)

                    case .failure(let error):
                        WireLogger.conversation.error("failed to create team one on one conversation: \(error)")
                    }
                }
            }
        }
    }
}
