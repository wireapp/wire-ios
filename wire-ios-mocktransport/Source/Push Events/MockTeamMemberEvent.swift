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

@objcMembers
public class MockTeamMemberEvent: NSObject {
    // MARK: Lifecycle

    public init(kind: Kind, team: MockTeam, user: MockUser) {
        self.kind = kind
        self.teamIdentifier = team.identifier
        self.userIdentifier = team.identifier
        self.data = [
            "user": user.identifier,
        ]
    }

    // MARK: Public

    public enum Kind: String {
        case leave = "team.member-leave"
    }

    public let data: [String: String]
    public let teamIdentifier: String
    public let userIdentifier: String
    public let kind: Kind
    public let timestamp = Date()

    public var payload: ZMTransportData {
        [
            "team": teamIdentifier,
            "time": timestamp.transportString(),
            "type": kind.rawValue,
            "data": data,
        ] as ZMTransportData
    }

    override public var debugDescription: String {
        "<\(type(of: self))> = \(kind.rawValue) team \(teamIdentifier) data: \(data)"
    }

    public static func createIfNeeded(
        team: MockTeam,
        changedValues: [String: Any],
        selfUser: MockUser
    ) -> [MockTeamMemberEvent] {
        let membersKey = #keyPath(MockTeam.members)
        let oldMembers = team.committedValues(forKeys: [membersKey])

        guard let currentMembers = changedValues[membersKey] as? Set<MockMember> else { return [] }
        let previousMembers = oldMembers[membersKey] as? Set<MockMember> ?? Set()

        guard    currentMembers.contains(where: { $0.user == selfUser })
            || previousMembers.contains(where: { $0.user == selfUser }) else { return [] }

        let removedMembersEvents = previousMembers
            .subtracting(currentMembers)
            .map { MockTeamMemberEvent(kind: .leave, team: team, user: $0.user) }

        return removedMembersEvents
    }
}
