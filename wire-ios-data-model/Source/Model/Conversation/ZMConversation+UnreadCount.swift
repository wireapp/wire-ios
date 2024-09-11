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

import Foundation

extension ZMConversation {
    /// Fetch all conversation that are marked as needsToCalculateUnreadMessages and calculate unread messages for them
    public static func calculateLastUnreadMessages(in managedObjectContext: NSManagedObjectContext) {
        let fetchRequest = sortedFetchRequest(with: predicateForConversationsNeedingToBeCalculatedUnreadMessages())
        let conversations = managedObjectContext.fetchOrAssert(request: fetchRequest) as? [ZMConversation]

        conversations?.forEach { $0.calculateLastUnreadMessages() }
    }

    /// Fetch all conversations that could potentially have unread messages and recalculate the latest unread messages
    /// for them.
    public static func recalculateUnreadMessages(in managedObjectContext: NSManagedObjectContext) {
        let fetchRequest = sortedFetchRequest(with: predicateForConversationConsideredUnread())

        if let conversations = managedObjectContext.fetchOrAssert(request: fetchRequest) as? [ZMConversation] {
            WireLogger.badgeCount.info("calculate last unread messages for \(conversations.count) conversations")
            conversations.forEach { $0.calculateLastUnreadMessages() }
        }
    }
}
