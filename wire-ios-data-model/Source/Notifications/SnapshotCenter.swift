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
import WireUtilities

// MARK: - Snapshot

struct Snapshot {
    let attributes: [String: NSObject?]
    let toManyRelationships: [String: Int]
    let toOneRelationships: [String: NSManagedObjectID]
}

// MARK: - Countable

protocol Countable {
    var count: Int { get }
}

// MARK: - NSOrderedSet + Countable

extension NSOrderedSet: Countable {}

// MARK: - NSSet + Countable

extension NSSet: Countable {}

// MARK: - SnapshotCenter

public class SnapshotCenter {
    // MARK: Lifecycle

    public init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
    }

    // MARK: Internal

    var snapshots: [NSManagedObjectID: Snapshot] = [:]

    func createSnapshots(for insertedObjects: Set<NSManagedObject>) {
        for insertedObject in insertedObjects {
            if insertedObject.objectID.isTemporaryID {
                try? managedObjectContext.obtainPermanentIDs(for: [insertedObject])
            }
            let newSnapshot = createSnapshot(for: insertedObject)
            snapshots[insertedObject.objectID] = newSnapshot
        }
    }

    func updateSnapshot(for object: NSManagedObject) {
        snapshots[object.objectID] = createSnapshot(for: object)
    }

    func createSnapshot(for object: NSManagedObject) -> Snapshot {
        let attributes = Array(object.entity.attributesByName.keys)
        let relationships = object.entity.relationshipsByName

        let attributesDict = attributes
            .mapToDictionaryWithOptionalValue { object.primitiveValue(forKey: $0) as? NSObject }

        let toManyRelationshipsDict: [String: Int] = relationships.reduce(into: .init()) { partialResult, item in
            guard
                item.value.isToMany,
                let newValue = (object.primitiveValue(forKey: item.key) as? Countable)?.count
            else {
                return
            }
            partialResult[item.key] = newValue
        }

        let toOneRelationshipsDict: [String: NSManagedObjectID] = relationships
            .reduce(into: .init()) { partialResult, item in
                guard
                    !item.value.isToMany,
                    let newValue = (object.primitiveValue(forKey: item.key) as? NSManagedObject)?.objectID
                else {
                    return
                }
                partialResult[item.key] = newValue
            }

        return Snapshot(
            attributes: attributesDict,
            toManyRelationships: toManyRelationshipsDict,
            toOneRelationships: toOneRelationshipsDict
        )
    }

    /// Before merging the sync into the ui context, we create a snapshot of all changed objects
    /// This function compares the snapshot values to the current ones and returns all keys and new values where the
    /// value changed due to the merge
    func extractChangedKeysFromSnapshot(for object: ZMManagedObject) -> Set<String> {
        guard let snapshot = snapshots[object.objectID] else {
            if object.objectID.isTemporaryID {
                try? managedObjectContext.obtainPermanentIDs(for: [object])
            }
            // create new snapshot
            let newSnapshot = createSnapshot(for: object)
            snapshots[object.objectID] = newSnapshot
            // return all keys as changed
            return Set(newSnapshot.attributes.keys)
                .union(newSnapshot.toManyRelationships.keys)
                .union(newSnapshot.toOneRelationships.keys)
        }

        var changedKeys = Set<String>()
        snapshot.attributes.forEach {
            let currentValue = object.primitiveValue(forKey: $0) as? NSObject
            if currentValue != $1 {
                changedKeys.insert($0)
            }
        }
        snapshot.toManyRelationships.forEach {
            guard let count = (object.value(forKey: $0) as? Countable)?.count, count != $1 else { return }
            changedKeys.insert($0)
        }
        snapshot.toOneRelationships.forEach {
            guard (object.value(forKey: $0) as? NSManagedObject)?.objectID != $1 else { return }
            changedKeys.insert($0)
        }
        // Update snapshot
        if !changedKeys.isEmpty {
            snapshots[object.objectID] = createSnapshot(for: object)
        }
        return changedKeys
    }

    func clearAllSnapshots() {
        snapshots = [:]
    }

    // MARK: Private

    private unowned var managedObjectContext: NSManagedObjectContext
}
