//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

extension ZMConversationMessage {

    var canAddReaction: Bool {
        guard let conversation = conversationLike else {
            return false
        }

        let participatesInConversation = conversation.localParticipantsContain(user: SelfUser.current)
        let sentOrDelivered = deliveryState.isOne(of: .sent, .delivered, .read)
        let likableType = isNormal && !isKnock
        return participatesInConversation && sentOrDelivered && likableType && !isObfuscated && !isEphemeral
    }

    var liked: Bool {
        get {
            return likers.contains { $0.isSelfUser }
        }

        set {
            if newValue {
                ZMMessage.addReaction(
                    "❤️",
                    to: self
                )
            } else {
                ZMMessage.removeReaction(
                    "❤️",
                    from: self
                )
            }
        }
    }

    var canVisitLink: Bool {
        guard let url = URL(string: textMessageData?.messageText ?? ""), UIApplication.shared.canOpenURL(url) else {
            return false
        }
        return true
    }

    func selfUserReactions() -> Set<Emoji.ID> {
        let result = usersReaction
            .filter { _, users in users.contains(where: \.isSelfUser) }
            .map(\.key)

        return Set(result)
    }

    func hasReactions() -> Bool {
        return usersReaction.contains { _, users in
            !users.isEmpty
        }
    }

    var likers: [UserType] {
        return usersReaction["❤️"] ?? []
    }

    var sortedLikers: [UserType] {
        return likers.sorted { $0.name < $1.name }
    }

    var sortedReadReceipts: [ReadReceipt] {
        return readReceipts.sorted { $0.userType.name < $1.userType.name }
    }

    func react(_ reaction: Emoji.ID) {
        if selfUserReactions().contains(reaction) {
            ZMMessage.removeReaction(
                reaction,
                from: self
            )
        } else {
            ZMMessage.addReaction(
                reaction,
                to: self
            )
        }
    }
}
