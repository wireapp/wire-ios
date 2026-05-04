//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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
    @objc var team: Team? {
        membership?.team
    }

    @objc
    static func keyPathsForValuesAffectingTeam() -> Set<String> {
        [#keyPath(ZMUser.membership)]
    }

    @objc var isWirelessUser: Bool {
        expiresAt != nil
    }

    @objc var isExpired: Bool {
        guard let expiresAt else {
            return false
        }

        return expiresAt.compare(Date()) != .orderedDescending
    }

    @objc var expiresAfter: TimeInterval {
        guard let expiresAt else {
            return 0
        }

        if expiresAt.timeIntervalSinceNow < 0 {
            return 0
        } else {
            return expiresAt.timeIntervalSinceNow
        }
    }

    @objc
    func createOrDeleteMembershipIfBelongingToTeam() {
        guard
            let teamIdentifier,
            let managedObjectContext
        else {
            return
        }

        let team: Team
        if isSelfUser {
            team = Team.fetchOrCreate(with: teamIdentifier, in: managedObjectContext)
            team.needsToBeUpdatedFromBackend = true
            team.needsToRedownloadMembers = true
        } else if let existingTeam = Team.fetch(with: teamIdentifier, in: managedObjectContext) {
            team = existingTeam
        } else {
            return
        }

        if !isAccountDeleted {
            createMembership(in: team, context: managedObjectContext)
        } else {
            deleteMembership(in: managedObjectContext)
        }
    }

    private func createMembership(in team: Team, context: NSManagedObjectContext) {
        _ = Member.getOrUpdateMember(for: self, in: team, context: context)
    }

    private func deleteMembership(in context: NSManagedObjectContext) {
        if let membership {
            context.delete(membership)
        }
    }

}
