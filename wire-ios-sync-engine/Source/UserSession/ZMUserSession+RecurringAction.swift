//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

extension ZMUserSession {

    func refreshUsersMissingMetadata() -> RecurringAction {
        /// Performing actions every 3 hours.
        let interval: TimeInterval = 3 * .hour

        return RecurringAction(id: "refreshUserMetadata", interval: interval) {
            self.perform {
                let fetchRequest = ZMUser.sortedFetchRequest(with: ZMUser.predicateForUsersArePendingToRefreshMetadata())
                guard let users = self.managedObjectContext.fetchOrAssert(request: fetchRequest) as? [ZMUser] else {
                    return
                }
                users.forEach { $0.refreshData() }
            }
        }
    }

    func refreshConversationsMissingMetadata() -> RecurringAction {
        /// Performing actions every 3 hours.
        let interval: TimeInterval = 3 * .hour
        
        return RecurringAction(id: "refreshConversationMetadata", interval: interval) {
            self.perform {
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: ZMConversation.entityName())
                fetchRequest.predicate = ZMConversation.predicateForConversationsArePendingToRefreshMetadata()

                guard let conversations = self.managedObjectContext.executeFetchRequestOrAssert(fetchRequest) as? [ZMConversation] else {
                    return
                }
                conversations.forEach { $0.needsToBeUpdatedFromBackend = true }
            }

        }
    }

}

extension TimeInterval {

    static let hour: Self = 60 * 60

}
