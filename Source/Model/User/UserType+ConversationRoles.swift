//
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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

public extension UserType {

    func canManagedGroupRole(of user: UserType, conversation: ZMConversation) -> Bool {
        guard isAdminGroup(conversation: conversation) else { return false }
        return !user.isSelfUser && (user.isConnected || isOnSameTeam(otherUser: user))
    }

    func isAdminGroup(conversation: ZMConversation) -> Bool {
        return role(in: conversation)?.name == ZMConversation.defaultAdminRoleName
    }

}
