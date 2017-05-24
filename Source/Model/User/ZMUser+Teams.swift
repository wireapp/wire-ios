//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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


public extension ZMUser {

    public var hasTeams: Bool {
        return memberships?.any { $0.team != nil } ?? false
    }

    public var teams: Set<Team> {
        guard let memberships = memberships else { return Set() }
        return Set(memberships.flatMap { $0.team })
    }
    
    static func keyPathsForValuesAffectingTeams() -> Set<String> {
        return Set([#keyPath(ZMUser.memberships)])
    }
    
    public var activeTeams: Set<Team> {
        return Set(teams.filter { $0.isActive })
    }

    public func isMember(of team: Team) -> Bool {
        return memberships?.any { team.isEqual($0.team) } ?? false
    }

    public func permissions(in team: Team) -> Permissions? {
        return membership(in: team)?.permissions
    }

    public func canCreateConversation(in team: Team) -> Bool {
        return permissions(in: team)?.contains(.createConversation) ?? false
    }

    public func isGuest(in conversation: ZMConversation) -> Bool {
        if isSelfUser {
            // In case the self user is a guest in a team conversation, the backend will
            // return a 403, ["label": "no-team-member"] when fetching said team.
            // We store the teamRemoteIdentifier of the team to check if we don't have a local team,
            // but received a teamId in the conversation payload, which means we are a guest in the conversation.
            return conversation.team == nil && conversation.teamRemoteIdentifier != nil
        } else {
            return conversation.otherActiveParticipants.contains(self)
                && conversation.team != nil
                && !isMember(of: conversation.team!)
        }
    }

    public func membership(in team: Team) -> Member? {
        return memberships?.first { team.isEqual($0.team) }
    }

}
