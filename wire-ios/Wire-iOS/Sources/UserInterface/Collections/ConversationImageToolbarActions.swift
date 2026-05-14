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

enum ConversationImageToolbarActions {

    struct State {

        let actions: [MessageAction]
        let hiddenActions: [MessageAction]

        func isHidden(_ action: MessageAction) -> Bool {
            hiddenActions.contains(action)
        }
    }

    static func state(
        isEphemeral: Bool,
        canDownloadMedia: Bool,
        canDelete: Bool
    ) -> State {
        let actions = actions(
            isEphemeral: isEphemeral,
            canDownloadMedia: canDownloadMedia
        )
        let hiddenActions: [MessageAction] = canDelete ? [] : [.delete]

        return State(actions: actions, hiddenActions: hiddenActions)
    }

    static func actions(
        isEphemeral: Bool,
        canDownloadMedia: Bool
    ) -> [MessageAction] {
        if isEphemeral {
            return [.delete]
        }

        if canDownloadMedia {
            return [.sketchDraw, .sketchEmoji, .copy, .save, .showInConversation, .delete]
        } else {
            return [.sketchDraw, .sketchEmoji, .showInConversation, .delete]
        }
    }

}
