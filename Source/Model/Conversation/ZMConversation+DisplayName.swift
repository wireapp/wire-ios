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

    @objc static private var emptyConversationEllipsis: String {
        return "…"
    }
    
    @objc static private var emptyGroupConversationName: String {
        return NSLocalizedString("conversation.displayname.emptygroup", comment: "")
    }

    /// This is equal to the meaningful display name, if it exists, otherwise a
    /// fallback placeholder name is used.
    ///
    @objc public var displayName: String {
        let result = self.meaningfulDisplayName
        switch conversationType {
        case .oneOnOne, .connection: return result ?? ZMConversation.emptyConversationEllipsis
        case .group: return result ?? ZMConversation.emptyGroupConversationName
        case .self, .invalid: return result ?? ""
        }
    }
    
    /// A meaningful display name is one that can be constructed from the conversation
    /// data, rather than relying on a fallback placeholder name, such as "…" or "Empty conversation".
    ///
    @objc public var meaningfulDisplayName: String? {
        switch conversationType {
        case .connection: return connectionDisplayName()
        case .group: return groupDisplayName()
        case .oneOnOne: return oneOnOneDisplayName()
        case .self: return managedObjectContext.map(ZMUser.selfUser)?.name
        case .invalid: return nil
        }
    }
    
    private func connectionDisplayName() -> String? {
        precondition(conversationType == .connection)

        let name: String?
        if let connectedName = connectedUser?.name, !connectedName.isEmpty {
            name = connectedName
        } else {
            name = userDefinedName
        }

        return name
    }

    private func groupDisplayName() -> String? {
        precondition(conversationType == .group)

        if let userDefined = userDefinedName, !userDefined.isEmpty {
            return userDefined
        }

        let selfUser = managedObjectContext.map(ZMUser.selfUser)

        let activeNames: [String] = lastServerSyncedActiveParticipants.compactMap { (user) -> String? in
            guard let user = user as? ZMUser, user != selfUser && !user.displayName.isEmpty else { return nil }
            return user.displayName
        }
        
        return activeNames.isEmpty ? nil : activeNames.joined(separator: ", ")
    }

    private func oneOnOneDisplayName() -> String? {
        precondition(conversationType == .oneOnOne)

        let other = lastServerSyncedActiveParticipants.firstObject as? ZMUser ?? connectedUser
        if let name = other?.name, !name.isEmpty {
            return name
        } else {
            return nil
        }
    }

}
