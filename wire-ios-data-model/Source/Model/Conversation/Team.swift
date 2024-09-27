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

extension NSNotification.Name {
    public static let teamDidRequestAsset = Notification.Name("TeamDidRequestAsset")
}

// MARK: - TeamType

public protocol TeamType: AnyObject {
    var conversations: Set<ZMConversation> { get }
    var name: String? { get }
    var pictureAssetId: String? { get }
    var pictureAssetKey: String? { get }
    var remoteIdentifier: UUID? { get }
    var imageData: Data? { get set }

    func requestImage()
    func refreshMetadata()
}

// MARK: - Team

@objcMembers
public class Team: ZMManagedObject, TeamType {
    @NSManaged public var conversations: Set<ZMConversation>
    @NSManaged public var members: Set<Member>
    @NSManaged public var roles: Set<Role>
    @NSManaged public var name: String?
    @NSManaged public var pictureAssetId: String?
    @NSManaged public var pictureAssetKey: String?
    @NSManaged public var creator: ZMUser?

    @NSManaged public var needsToRedownloadMembers: Bool
    @NSManaged public var needsToDownloadRoles: Bool

    @NSManaged private var remoteIdentifier_data: Data?

    public var remoteIdentifier: UUID? {
        get {
            guard let data = remoteIdentifier_data else { return nil }
            return UUID(data: data)
        }
        set {
            remoteIdentifier_data = newValue?.uuidData
        }
    }

    override public static func entityName() -> String {
        "Team"
    }

    override public static func sortKey() -> String {
        #keyPath(Team.name)
    }

    override public static func isTrackingLocalModifications() -> Bool {
        false
    }

    @objc(fetchOrCreateTeamWithRemoteIdentifier:inContext:)
    public static func fetchOrCreate(with identifier: UUID, in context: NSManagedObjectContext) -> Team {
        if let existing = Team.fetch(with: identifier, in: context) {
            return existing
        }

        precondition(context.zm_isSyncContext, "Needs to be called on the sync context")
        let team = Team.insertNewObject(in: context)
        team.remoteIdentifier = identifier
        return team
    }

    public func refreshMetadata() {
        needsToBeUpdatedFromBackend = true
    }
}

extension Team {
    public func members(matchingQuery query: String) -> [Member] {
        let searchPredicate = ZMUser.predicateForAllUsers(withSearch: query)

        return members
            .filter { member in
                guard let user = member.user else {
                    return false
                }
                return !user.isSelfUser && searchPredicate.evaluate(with: user)
            }
            .sortedAscendingPrependingNil { $0.user?.normalizedName }
    }
}

// MARK: - Logo Image

extension Team {
    @objc static let pictureAssetIdKey = #keyPath(Team.pictureAssetId)

    public var imageData: Data? {
        get {
            guard let cache = managedObjectContext?.zm_fileAssetCache else {
                return nil
            }

            return cache.imageData(for: self)
        }

        set {
            guard let cache = managedObjectContext?.zm_fileAssetCache else {
                return
            }

            if let newValue {
                cache.storeImage(data: newValue, for: self)
            } else {
                cache.deleteImageData(for: self)
            }

            if let uiContext = managedObjectContext?.zm_userInterface {
                // Notify about a non core data change since the image is persisted in the file cache
                NotificationDispatcher.notifyNonCoreDataChanges(
                    objectID: objectID,
                    changedKeys: [#keyPath(Team.imageData)],
                    uiContext: uiContext
                )
            }
        }
    }

    public func requestImage() {
        guard
            let context = managedObjectContext,
            context.zm_isUserInterfaceContext,
            let cache = context.zm_fileAssetCache,
            !cache.hasImageData(for: self)
        else {
            return
        }

        NotificationInContext(
            name: .teamDidRequestAsset,
            context: context.notificationContext,
            object: objectID
        ).post()
    }

    public static var imageDownloadFilter: NSPredicate {
        let assetIdExists = NSPredicate(format: "(%K != nil)", Team.pictureAssetIdKey)
        let notCached = NSPredicate { team, _ -> Bool in
            guard let team = team as? Team else { return false }
            return team.imageData == nil
        }
        return NSCompoundPredicate(andPredicateWithSubpredicates: [assetIdExists, notCached])
    }
}
