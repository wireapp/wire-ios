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


public protocol TeamType: class {

    var conversations: Set<ZMConversation> { get }
    var name: String? { get }
    var pictureAssetId: String? { get }
    var pictureAssetKey: String? { get }
    var isActive: Bool { get set }
    var remoteIdentifier: UUID? { get }

}


public class Team: ZMManagedObject, TeamType {

    @NSManaged public var conversations: Set<ZMConversation>
    @NSManaged public var members: Set<Member>
    @NSManaged public var name: String?
    @NSManaged public var pictureAssetId: String?
    @NSManaged public var pictureAssetKey: String?
    @NSManaged public var isActive: Bool
    @NSManaged public var creator: ZMUser?

    @NSManaged public var needsToRedownloadMembers: Bool
    @NSManaged private var remoteIdentifier_data: Data?

    public var remoteIdentifier: UUID? {
        get { return remoteIdentifier_data.flatMap { NSUUID(uuidBytes: $0.withUnsafeBytes(UnsafePointer<UInt8>.init)) } as UUID? }
        set { remoteIdentifier_data = (newValue as NSUUID?)?.data() }
    }

    public override static func entityName() -> String {
        return "Team"
    }

    override public static func sortKey() -> String {
        return #keyPath(Team.name)
    }

    public override static func isTrackingLocalModifications() -> Bool {
        return false
    }

    @objc(fetchOrCreateTeamWithRemoteIdentifier:createIfNeeded:inContext:created:)
    public static func fetchOrCreate(with identifier: UUID, create: Bool, in context: NSManagedObjectContext, created: UnsafeMutablePointer<Bool>?) -> Team? {
        precondition(!create || context.zm_isSyncContext, "Needs to be called on the sync context")
        if let existing = Team.fetch(withRemoteIdentifier: identifier, in: context) {
            created?.pointee = false
            return existing
        } else if create {
            let team = Team.insertNewObject(in: context)
            team.remoteIdentifier = identifier
            created?.pointee = true
            return team
        }

        return nil
    }
}


public enum TeamError: Error {
    case insufficientPermissions
}

extension Team {

    public func addConversation(with participants: Set<ZMUser>) throws -> ZMConversation? {
        guard ZMUser.selfUser(in: managedObjectContext!).canCreateConversation(in: self) else { throw TeamError.insufficientPermissions }
        switch participants.count {
        case 1: return ZMConversation.fetchOrCreateTeamConversation(in: managedObjectContext!, withParticipant: participants.first!, team: self)
        default: return ZMConversation.insertGroupConversation(into: managedObjectContext!, withParticipants: Array(participants), in: self)
        }
    }

}

extension Team {
    
    public func members(matchingQuery query: String) -> [Member] {
        let searchPredicate = ZMUser.predicateForAllUsers(withSearch: query)

        return members.filter({ member in
            guard let user = member.user else { return false }
            
            return !user.isSelfUser && searchPredicate.evaluate(with: user)
        }).sorted(by: { (first, second) -> Bool in
            return first.user?.normalizedName < second.user?.normalizedName
        })
    }
    
    public static func predicateTeamsWithGuestUserInAnyConversation(guestUser: ZMUser) -> NSPredicate {
        let notInThisTeam = NSPredicate(format: "NOT (SELF IN %@)", guestUser.teams)
        let participantInAnyConversation = NSPredicate(format: "SUBQUERY(%K, $conversation, %@ IN $conversation.%K).@count > 0", #keyPath(Team.conversations), guestUser, #keyPath(ZMConversation.otherActiveParticipants))
        return NSCompoundPredicate(andPredicateWithSubpredicates: [notInThisTeam, participantInAnyConversation])
    }
    
    public static func teamsWithGuestInAnyConversation(inContext context: NSManagedObjectContext, guestUser: ZMUser) -> [Team] {
        let predicate = self.predicateTeamsWithGuestUserInAnyConversation(guestUser: guestUser)
        let fetchRequest = Team.sortedFetchRequest(with: predicate)
        guard let teams = context.executeFetchRequestOrAssert(fetchRequest) as? [Team] else { return [] }
        return teams
    }
    
}
