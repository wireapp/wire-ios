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

import WireDataModel

public struct SystemMessage {
    let type: ZMSystemMessageType
    let sender: ZMUser
    let users: Set<ZMUser>?
    let addedUsers: Set<ZMUser>
    let clients: Set<WireDataModel.UserClient>?
    let timestamp: Date
    let duration: TimeInterval?
    let messageTimer: Double?
    let relevantForStatus: Bool
    let removedReason: ZMParticipantsRemovedReason
    let domains: [String]?
    
    public init(
        type: ZMSystemMessageType,
        sender: ZMUser,
        users: Set<ZMUser>? = nil,
        addedUsers: Set<ZMUser> = Set(),
        clients: Set<WireDataModel.UserClient>? = nil,
        timestamp: Date,
        duration: TimeInterval? = nil,
        messageTimer: Double? = nil,
        relevantForStatus: Bool = true,
        removedReason: ZMParticipantsRemovedReason = .none,
        domains: [String]? = nil
    ) {
        self.type = type
        self.sender = sender
        self.users = users
        self.addedUsers = addedUsers
        self.clients = clients
        self.timestamp = timestamp
        self.duration = duration
        self.messageTimer = messageTimer
        self.relevantForStatus = relevantForStatus
        self.removedReason = removedReason
        self.domains = domains
    }
}
