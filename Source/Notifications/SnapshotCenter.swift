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

import Foundation

struct Snapshot {
    let attributes : [String : NSObject?]
    let toManyRelationships : [String : Int]
}

protocol Countable {
    var count : Int { get }
}

extension NSOrderedSet : Countable {}
extension NSSet : Countable {}

public class SnapshotCenter {
    
    private unowned var managedObjectContext: NSManagedObjectContext
    internal var snapshots : [NSManagedObjectID : Snapshot] = [:]
    
    public init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
    }
    
    /// This function needs to be called when the sync context saved and we receive the NSManagedObjectContextDidSave notification and before the changes are merged into the UI context
    func willMergeChanges(changes: Set<NSManagedObjectID>){
        let newSnapshots : [NSManagedObjectID : Snapshot] = changes.mapToDictionary{ objectID in
            guard let obj = (try? managedObjectContext.existingObject(with: objectID)) else { return nil }
            return snapshot(for: obj)
        }
        newSnapshots.forEach{ (key, value) in
            if snapshots[key] == nil {
                snapshots[key] = value
            }
        }
    }
    
    func removeSnapshot(for object: NSManagedObject) {
        snapshots.removeValue(forKey: object.objectID)
    }
    
    func snapshot(for object: NSManagedObject) -> Snapshot {
        let attributes = Array(object.entity.attributesByName.keys)
        let relationShips = object.entity.relationshipsByName
        
        let attributesDict = attributes.mapToDictionaryWithOptionalValue{object.primitiveValue(forKey: $0) as? NSObject}
        let relationshipsDict : [String : Int] = relationShips.mapping(keysMapping: {$0}, valueMapping: { (key, relationShipDescription) in
            guard relationShipDescription.isToMany else { return nil}
            return (object.primitiveValue(forKey: key) as? Countable)?.count
        })
        return Snapshot(attributes : attributesDict, toManyRelationships : relationshipsDict)
    }
    
    /// Before merging the sync into the ui context, we create a snapshot of all changed objects
    /// This function compares the snapshot values to the current ones and returns all keys and new values where the value changed due to the merge
    func extractChangedKeysFromSnapshot(for object: ZMManagedObject) -> Set<String> {
        guard let snapshot = snapshots[object.objectID] else { return Set()}
        var changedKeys = Set<String>()
        snapshot.attributes.forEach{
            let currentValue = object.value(forKey: $0) as? NSObject
            if currentValue != $1  {
                changedKeys.insert($0)
            }
        }
        snapshot.toManyRelationships.forEach{
            guard let count = (object.value(forKey: $0) as? Countable)?.count, count != $1 else { return }
            changedKeys.insert($0)
        }
        snapshots.removeValue(forKey: object.objectID)
        return changedKeys
    }
    
    func clearAllSnapshots(){
        snapshots = [:]
    }
    
}
