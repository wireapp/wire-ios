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

extension ZMConversation {
    /// A meaningful display name is one that can be constructed from the conversation data
    @objc public var displayName: String? {
        switch conversationType {
        case .connection: connectionDisplayName()
        case .group: groupDisplayName()
        case .oneOnOne: oneOnOneDisplayName()
        case .self: managedObjectContext.map(ZMUser.selfUser)?.name
        case .invalid: nil
        }
    }

    private func connectionDisplayName() -> String? {
        precondition(conversationType == .connection)

        return if let connectedName = connectedUser?.name, !connectedName.isEmpty {
            connectedName
        } else {
            userDefinedName
        }
    }

    private var selfUser: ZMUser? {
        managedObjectContext.map(ZMUser.selfUser)
    }

    /// Get the group name from the participants
    ///
    /// - Returns: a group name with creator at the first and other users sorted by name
    private func groupDisplayName() -> String? {
        precondition(conversationType == .group)

        if let userDefined = userDefinedName, !userDefined.isEmpty {
            return userDefined
        }

        let activeNames: [String] = localParticipants.compactMap { user -> String? in
            guard user != selfUser else { return nil }
            return user.name
        }

        return activeNames.isEmpty ? nil : activeNames.sorted().joined(separator: ", ")
    }

    private func oneOnOneDisplayName() -> String? {
        precondition(conversationType == .oneOnOne)

        let other = localParticipantsExcludingSelf.first ?? connectedUser
        if let name = other?.name, !name.isEmpty {
            return name
        } else {
            return nil
        }
    }
}
