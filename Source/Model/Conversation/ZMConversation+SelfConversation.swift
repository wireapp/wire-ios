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

extension ZMConversation {
    static func updateConversation(withLastReadFromSelfConversation lastRead: LastRead, inContext moc: NSManagedObjectContext) {
        let newTimeStamp = Double(integerLiteral: lastRead.lastReadTimestamp)
        let timestamp = Date(timeIntervalSince1970: newTimeStamp/1000)
        guard let conversationID = UUID(uuidString: lastRead.conversationID) else {
            return
        }
        let conversation = ZMConversation(remoteID: conversationID, createIfNeeded: true, in: moc)
        conversation?.updateLastRead(timestamp, synchronize: false)
    }
    
    static func updateConversation(withClearedFromSelfConversation cleared: Cleared, inContext moc: NSManagedObjectContext) {
        let newTimeStamp = Double(integerLiteral: cleared.clearedTimestamp)
        let timestamp = Date(timeIntervalSince1970: newTimeStamp/1000)
        guard let conversationID = UUID(uuidString: cleared.conversationID) else {
            return
        }
        let conversation = ZMConversation(remoteID: conversationID, createIfNeeded: true, in: moc)
        conversation?.updateCleared(timestamp, synchronize: false)
        
    }
}
