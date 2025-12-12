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

import WireSyncEngine

final class ConversationAvatarView: UIView {
    enum Context {
        // one or more users requesting connection to self user
        case connect(users: [UserType])
        // an established conversation or self user has a pending request to other users
        case conversation(conversation: ConversationGroupAvatarViewConversation)
    }

    lazy var connectAvatarView: ConversationConnectAvatarView = {
        let view = ConversationConnectAvatarView()
        addSubview(view)
        view.fitIn(view: self)
        view.isHidden = true
        return view
    }()

    lazy var groupIconAvatarView: ConversationGroupAvatarView = {
        let view = ConversationGroupAvatarView()
        addSubview(view)
        view.fitIn(view: self)
        view.isHidden = true
        return view
    }()

    fileprivate func configureForOneOnOne(_ users: [any UserType]) {
        connectAvatarView.configure(context: ConversationConnectAvatarView.Context(users: users))
        connectAvatarView.isHidden = false
        groupIconAvatarView.isHidden = true
    }

    func configure(context: Context) {

        switch context {
        case let .connect(users: users):
            configureForOneOnOne(users)
        case let .conversation(conversation: conversation) where conversation.conversationType == .group:
            let users = conversation.stableRandomParticipants.filter { !$0.isSelfUser }
            if let user = users.first, user.isAppOrBot {
                configureForOneOnOne(users)
                break
            }

            configureForGroup(conversation)
        case let .conversation(conversation: conversation) where conversation.conversationType == .oneOnOne:
            let users = conversation.stableRandomParticipants.filter { !$0.isSelfUser }
            configureForOneOnOne(users)
        default:
            configureForOneOnOne([])
        }
    }

    private func configureForGroup(_ conversation: any ConversationGroupAvatarViewConversation) {
        groupIconAvatarView.configure(context: ConversationGroupAvatarView.Context(
            conversation: conversation
        ))
        connectAvatarView.isHidden = true
        groupIconAvatarView.isHidden = false
    }
}
