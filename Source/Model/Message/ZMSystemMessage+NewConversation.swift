//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

public extension ZMSystemMessage {
    @NSManaged public var numberOfGuestsAdded: Int16  // Only filled for .newConversation
    @NSManaged public var allTeamUsersAdded: Bool     // Only filled for .newConversation
}

extension ZMSystemMessage {

    @objc(updateNewConversationSystemMessageIfNeededWithUsers:context:conversation:)
    func updateNewConversationSystemMessagePropertiesIfNeeded(
        users: Set<ZMUser>,
        context: NSManagedObjectContext,
        conversation: ZMConversation
        ) {
        guard systemMessageType == .newConversation else { return }
        guard let team = ZMUser.selfUser(in: context).team else { return }
        
        let members = team.members.compactMap { $0.user }
        let guests = users.filter { $0.isGuest(in: conversation) }

        allTeamUsersAdded = users.isSuperset(of: members)
        numberOfGuestsAdded = Int16(guests.count)
    }

}
