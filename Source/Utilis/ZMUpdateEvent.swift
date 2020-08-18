//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

extension ZMUpdateEvent {
    public var messageNonce: UUID? {
        switch type {
        case .conversationMessageAdd,
             .conversationAssetAdd,
             .conversationKnock:
            return payload.dictionary(forKey: "data")?["nonce"] as? UUID
        case .conversationClientMessageAdd,
             .conversationOtrMessageAdd,
             .conversationOtrAssetAdd:
            let message = GenericMessage(from: self)
            guard let messageID = message?.messageID else {
                return nil
            }
            return UUID(uuidString: messageID)
        default:
            return nil
        }
    }
    
    public var userIDs: [UUID] {
        guard let dataPayload = (payload as NSDictionary).dictionary(forKey: "data"),
            let userIds = dataPayload["user_ids"] as? [String] else {
                return []
        }
        return userIds.compactMap({ UUID.init(uuidString: $0)})
    }
}
