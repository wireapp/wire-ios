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

import CoreData
import Foundation

/// A managed object representing an MLS group that is primarily being used 
/// to store the last key material update date for a group.

@objcMembers
public class MLSGroup: ZMManagedObject {

    public override static func entityName() -> String {
        return "MLSGroup"
    }

    public override class func sortKey() -> String? {
        return nil
    }

    public override class func isTrackingLocalModifications() -> Bool {
        return false
    }

    // MARK: - Properties

    public var id: MLSGroupID {
        get {
            willAccessValue(forKey: Self.idKey)

            guard let value = primitiveId else {
                // log
                fatalError("trying to access MLSGroup ID before setting it")
            }

            didAccessValue(forKey: Self.idKey)
            return MLSGroupID(value)
        }

        set {
            willChangeValue(forKey: Self.idKey)
            primitiveId = newValue.data
            didChangeValue(forKey: Self.idKey)
        }
    }

    static let idKey = "id"

    @NSManaged
    private var primitiveId: Data?

    @NSManaged
    public var lastKeyMaterialUpdate: Date?

    // MARK: - Methods

    public class func updateOrCreate(
        id: MLSGroupID,
        inSyncContext context: NSManagedObjectContext,
        changes: @escaping (MLSGroup) -> Void
    ) {
        assert(
            context.zm_isSyncContext,
            "Modifications of `MLSGroupID` can only occur on the sync context"
        )

        context.performAndWait {
            if let existing = fetch(id: id, in: context) {
                changes(existing)
            } else {
                let newGroup = insertNewObject(in: context)
                newGroup.id = id
                changes(newGroup)
            }

            context.saveOrRollback()
        }
    }

    class func fetch(id: MLSGroupID, in context: NSManagedObjectContext) -> MLSGroup? {
        let request = NSFetchRequest<MLSGroup>(entityName: entityName())
        request.predicate = NSPredicate(format: "\(idKey) == %@", argumentArray: [id.data])
        request.fetchLimit = 2

        let result = context.fetchOrAssert(request: request)
        require(result.count <= 1, "More than one instance of MLSGroupID with id: \(id)")
        return result.first
    }

    class func fetchAllObjects(in context: NSManagedObjectContext) -> Set<MLSGroup> {
        let request = NSFetchRequest<MLSGroup>(entityName: entityName())
        let result = context.fetchOrAssert(request: request)
        return Set(result)
    }

}
