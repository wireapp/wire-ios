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

import WireDataModel

final class ConversationPreviewViewModel {

    struct State: Equatable {
        let title: String
        let content: Content
        let actions: [PreviewAction]
    }

    enum Content: Equatable {
        case ready
        case empty(message: String)
        case loading(message: String?)
        case error(message: String)
    }

    struct PreviewAction: Equatable {
        let conversationAction: ZMConversation.Action
        let title: String
        let style: ActionStyle
    }

    enum ActionStyle: Equatable {
        case `default`
        case destructive
    }

    enum Route {
        case performConversationAction(ZMConversation.Action)
        case openConversation(ZMConversation)
        case dismissPreview
    }

    let conversation: ZMConversation
    private let actions: [ZMConversation.Action]

    var state: State {
        State(
            title: conversation.displayNameWithFallback,
            content: .ready,
            actions: actions.map { action in
                PreviewAction(
                    conversationAction: action,
                    title: action.title,
                    style: action.isConversationPreviewDestructive ? .destructive : .default
                )
            }
        )
    }

    init(conversation: ZMConversation) {
        self.conversation = conversation
        self.actions = conversation.listActions
    }

    init(conversation: ZMConversation, actions: [ZMConversation.Action]) {
        self.conversation = conversation
        self.actions = actions
    }

    func routeForPreviewAction(at index: Int) -> Route {
        guard actions.indices.contains(index) else {
            return .dismissPreview
        }

        return .performConversationAction(actions[index])
    }

    func routeForCommit() -> Route {
        .openConversation(conversation)
    }
}

private extension ZMConversation.Action {

    var isConversationPreviewDestructive: Bool {
        switch self {
        case .remove,
             .delete:
            true
        default:
            false
        }
    }
}
