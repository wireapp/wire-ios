//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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


public extension ZMConversation {

    static private var emptyConversationEllipsis: String {
        return "…"
    }

    public var displayName: String {
        switch conversationType {
        case .connection: return connectionDisplayName()
        case .group: return groupDisplayName()
        case .oneOnOne: return oneOnOneDisplayName()
        case .self: return managedObjectContext.map(ZMUser.selfUser)?.name ?? ""
        case .invalid: return ""
        }
    }

    private func connectionDisplayName() -> String {
        precondition(conversationType == .connection)

        let name: String?
        if let connectedName = connectedUser?.name, connectedName.characters.count > 0 {
            name = connectedName
        } else {
            name = userDefinedName
        }

        return name ?? ZMConversation.emptyConversationEllipsis
    }

    private func groupDisplayName() -> String {
        precondition(conversationType == .group)

        if let userDefined = userDefinedName, userDefined.characters.count > 0 {
            return userDefined
        }

        let selfUser = managedObjectContext.map(ZMUser.selfUser)
        let activeNames: [String] = otherActiveParticipants.flatMap {
            guard let user = $0 as? ZMUser, user != selfUser && user.displayName?.characters.count > 0 else { return nil }
            return user.displayName
        }

        if activeNames.count > 0 {
            return activeNames.joined(separator: ", ")
        } else {
            return NSLocalizedString("conversation.displayname.emptygroup", comment: "")
        }
    }

    private func oneOnOneDisplayName() -> String {
        precondition(conversationType == .oneOnOne)

        let other = otherActiveParticipants.firstObject as? ZMUser ?? connectedUser
        if let name = other?.name, name.characters.count > 0 {
            return name
        } else {
            return ZMConversation.emptyConversationEllipsis
        }
    }

}
