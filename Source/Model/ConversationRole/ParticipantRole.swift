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

let ZMParticipantRoleRoleValueKey           = #keyPath(ParticipantRole.role)
let ZMParticipantRoleOperationToSyncKey     = #keyPath(ParticipantRole.operationToSync)
let ZMParticipantRoleModificationToSyncKey  = #keyPath(ParticipantRole.rawOperationToSync)

@objcMembers
final public class ParticipantRole: ZMManagedObject {
    
    @objc @NSManaged var rawOperationToSync: Int16
    @NSManaged public var conversation: ZMConversation?
    @NSManaged public var user: ZMUser
    @NSManaged public var role: Role?
    
    @objc
    public enum OperationToSync: Int16 {
        case none = 0
        case insert = 1
        case delete = 2
    }
    
    @objc
    public var operationToSync: OperationToSync {
        get {
            return OperationToSync(rawValue: self.rawOperationToSync) ?? .none
        }
        set {
            self.rawOperationToSync = newValue.rawValue
        }
    }
    
    @objc
    public class func keyPathsForValuesAffectingOperationToSync() -> Set<String> {
        return Set([ZMParticipantRoleModificationToSyncKey])
    }
    
    @objc
    public var markedForDeletion: Bool {
        return self.operationToSync == .delete
    }
    
    @objc
    public class func keyPathsForValuesAffectingMarkedForDeletion() -> Set<String> {
        return Set([ZMParticipantRoleModificationToSyncKey])
    }
    
    @objc
    public var markedForInsertion: Bool {
        return self.operationToSync == .insert
    }
    
    @objc
    public class func keyPathsForValuesAffectingMarkedForInsertion() -> Set<String> {
        return Set([ZMParticipantRoleModificationToSyncKey])
    }

    public override static func predicateForObjectsThatNeedToBeInsertedUpstream() -> NSPredicate? {
        return NSPredicate(format: "%K == %d", #keyPath(rawOperationToSync), OperationToSync.insert.rawValue)
    }
    
    public override static func predicateForObjectsThatNeedToBeUpdatedUpstream() -> NSPredicate? {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            super.predicateForObjectsThatNeedToBeUpdatedUpstream()!,
            NSPredicate(format: "%K != %d", #keyPath(rawOperationToSync), OperationToSync.none.rawValue)
        ])
    }

    public override static func entityName() -> String {
        return "ParticipantRole"
    }
    
    public override static func isTrackingLocalModifications() -> Bool {
        return true
    }
    
    public override func keysTrackedForLocalModifications() -> Set<String> {
        return [ZMParticipantRoleRoleValueKey,
                ZMParticipantRoleOperationToSyncKey]
    }
    
    @objc
    @discardableResult
    static public func create(managedObjectContext: NSManagedObjectContext,
                              user: ZMUser,
                              conversation: ZMConversation) -> ParticipantRole {
        let entry = ParticipantRole.insertNewObject(in: managedObjectContext)
        entry.user = user
        entry.conversation = conversation
        return entry
    }
}

