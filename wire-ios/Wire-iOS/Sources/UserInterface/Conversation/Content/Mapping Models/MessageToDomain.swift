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

import WireDataModel
import WireMessagingDomain

extension ZMMessage {
    func toDomain() -> MessageModel {
        MessageModel(
            objectID: objectID,
            serverTimestamp: serverTimestamp,
            sender: sender?.toDomain(),
            kind: getMessageKind(),
            reactions: reactions.toDomain()
        )
    }

    func getMessageKind() -> MessageModel.Kind {
        if let textMessageData {
            return .text(TextMessageModel(text: textMessageData.messageText))
        }
        return .text(TextMessageModel(text: "Not supported message type yet"))
    }
}

extension Collection<Reaction> {
    func toDomain() -> ReactionsModel {
        Array(self)
            .partition(by: \.unicodeValue)
            .mapValues {
                $0.flatMap(\.users)
                    .map { $0.toDomain() }
            }
    }
}
