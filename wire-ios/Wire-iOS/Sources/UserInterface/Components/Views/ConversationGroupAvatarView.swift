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

import SwiftUI
import WireMessagingAssembly
import WireSyncEngine

typealias ConversationGroupAvatarViewConversation
    = ConversationLike & HasQualifiedID & StableRandomParticipantsProvider

final class ConversationGroupAvatarView: UIView {
    struct Context {
        // an established conversation or self user has a pending request to other users
        let conversation: ConversationGroupAvatarViewConversation
    }

    func configure(context: Context) {
        let conversation = context.conversation

        guard let id = context.conversation.qualifiedID?.uuid.uuidString else {
            iconContainer.removeSubviews()
            return
        }

        let iconView = if conversation.isChannel {
            // TODO: [WPB-16527] Pass in correct `isPrivateChannel` when we implement public channels
            ConversationChannelIconFactory().createUIKit(conversationID: id, isPrivateChannel: true)
        } else {
            ConversationGroupIconFactory().createUIKit(conversationID: id)
        }

        iconContainer.removeSubviews()
        iconContainer.addSubview(iconView)
        iconView.fitIn(view: iconContainer)

        typealias Avatar = L10n.Accessibility.ConversationsList.ItemCell.Avatar
        accessibilityLabel = conversation.isChannel ? Avatar.Channel.label : Avatar.Group.label
        isAccessibilityElement = true
    }

    private var qualifiedID: QualifiedID? = .none

    lazy var iconContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.clipsToBounds = false
        view.layer.cornerRadius = 4
        return view
    }()

    init() {
        super.init(frame: .zero)

        autoresizesSubviews = false
        layer.masksToBounds = false
        addSubview(iconContainer)
        iconContainer.fitIn(view: self)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds != .zero else {
            return
        }

        iconContainer.frame = bounds

        layer.cornerRadius = 6
        iconContainer.layer.cornerRadius = 4
    }
}
