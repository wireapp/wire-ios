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

import Foundation
import WireDataModel

private let linkDetector = NSDataDetector.linkDetector

extension ZMConversationMessage {

    var canAddReaction: Bool {
        guard let conversation = conversationLike else {
            return false
        }

        guard let user = SelfUser.provider?.providedSelfUser else {
            assertionFailure("expected available 'user'!")
            return false
        }

        let participatesInConversation = conversation.localParticipantsContain(user: user)
        let sentOrDelivered = deliveryState.isOne(of: .sent, .delivered, .read)
        let likableType = isNormal && !isKnock
        return participatesInConversation && sentOrDelivered && likableType && !isObfuscated && !isEphemeral
    }

    var liked: Bool {
        get {
            likers.contains { $0.isSelfUser }
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
        let content = textMessageData?.linkPreview?.originalURLString ?? textMessageData?.messageText
        guard let content, let url = linkDetector?.detectLinks(in: content).first else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    func selfUserReactions() -> Set<Emoji.ID> {
        let result = usersReaction
            .filter { _, users in users.contains(where: \.isSelfUser) }
            .map(\.key)

        return Set(result)
    }

    func hasReactions() -> Bool {
        usersReaction.contains { _, users in
            !users.isEmpty
        }
    }

    var likers: [UserType] {
        usersReaction["❤️"] ?? []
    }

    var sortedLikers: [UserType] {
        likers.sortedAscendingPrependingNil(by: \.name)
    }

    var sortedReadReceipts: [ReadReceipt] {
        readReceipts.sortedAscendingPrependingNil(by: \.userType.name)
    }

}
