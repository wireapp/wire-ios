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
import ZMCSystem
import ZMUtilities



// Objects that need to be in a snapshot should implement this protocol. It will be used to
// set flags on the ObjectChangeInfo
public protocol ObjectInSnapshot : NSObjectProtocol {
    
    var observableKeys : [String] { get }

    // Needed because NSObjectProtocol != NSObject
    func value(forKey key: String) -> Any?
}

protocol ValueToCopy : NSCopying {}

extension NSOrderedSet : ValueToCopy {}
extension NSSet : ValueToCopy {}

public struct ObjectSnapshot : Equatable, CustomDebugStringConvertible
{
    
    public typealias KeysAndValues = [KeyPath : NSObject]
    public typealias KeysAndOldValues = [KeyPath : NSObject?]
    
    typealias KeysFromTheSameObjectThatAffectKey = [KeyPath : KeySet]

    fileprivate let snapshotValues : KeysAndValues
    
    fileprivate let snapshotKeys : KeySet
    
    fileprivate let keyToAffectedKeys : KeysFromTheSameObjectThatAffectKey // userDefinedName -> displayName, otherActiveParticipants -> displayName, ...
    
    public init(object: NSObject, keys: KeySet) {
        
        self.snapshotKeys = keys
        var snapshotValues : KeysAndValues = [:]
        self.keyToAffectedKeys = ObjectSnapshot.extractKeysAffectingValuesForKeysToSnapshot(object, snapshotKeys: keys)
        
        for key in keys {
            let value = object.value(forKey: key.rawValue)
            if let nonNilValue = value {
                switch (nonNilValue) {
                    
                case let set as Set<NSObject>:
                    snapshotValues[key] = Set(Array(set)) as NSObject? // This is to materialize potential faults
                    
                case let set as NSOrderedSet:
                    snapshotValues[key] = NSOrderedSet(array: set.array) // This is to materialize potential faults
                    
                case let set as [NSObject]:
                    snapshotValues[key] = set.map { $0 } as NSObject? // This is to materialize potential faults
                case let set as NSObject where set is NSCopying:
                    if let copy = (set as! NSCopying).copy(with: nil) as? NSObject {
                        snapshotValues[key] = copy
                    } else {
                        fatal("Can't copy snapshot value for key \(key)")
                    }
                case let objectValue as NSObject:
                    snapshotValues[key] = objectValue
                default:
                    fatal("Can't snapshot value \(key)")
                }
            }
        }
        self.snapshotValues = snapshotValues
    }
    
    fileprivate static func extractKeysAffectingValuesForKeysToSnapshot(_ object: NSObject, snapshotKeys: KeySet) -> KeysFromTheSameObjectThatAffectKey
    {
        var mappedKeys: [KeyPath : KeySet] = [:]
        for affectedKey in snapshotKeys {
            for affectingKey in ObjectSnapshot.keysFromTheSameObjectThatAffectKeyOfObject(object, key:affectedKey) {
                
                var keySet: KeySet
                
                if let previousSet = mappedKeys[affectingKey] {
                    keySet = previousSet.union(KeySet(key: affectedKey))
                } else {
                    keySet = KeySet(key: affectedKey)
                }
                mappedKeys[affectingKey] = keySet
            }
        }
        
        return mappedKeys
    }
    
    public func updatedSnapshot(_ object: NSObject, affectedKeys: AffectedKeys) -> (ObjectSnapshot, KeysAndOldValues)? {
        let keysArray = Array<KeyPath>(self.keyToAffectedKeys.keys)
        let keysThatChangedBecauseAffectedKeysChanged = keysArray.filter { affectedKeys.containsKey($0) }
                                                                 .map { self.keyToAffectedKeys[$0]! }
                                                                 .reduce(KeySet(), {$0.union($1)})
        

        let keysToCheck = self.snapshotKeys.filter { affectedKeys.containsKey($0) }.union(keysThatChangedBecauseAffectedKeysChanged)
        let keysThatChanged : KeySet = keysToCheck.filter { key in
            
            let currentValue = object.value(forKey: key.rawValue) as? NSObject
            if let oldValue = self.snapshotValues[key] {
                // old value was not nil
                return currentValue != oldValue
            } else {
                // old value was nil
                return currentValue != nil
            }
        }
        
        let changedSnapshotKeys: KeysAndOldValues = {
            var c: KeysAndOldValues = [:]
            for key in keysThatChanged {
                let value = self.snapshotValues[key]
                c[key] = value
            }
            return c
        }()
        
        if !changedSnapshotKeys.isEmpty {
            let newSnapshot = ObjectSnapshot(object: object, keys: self.snapshotKeys)
            return (newSnapshot, changedSnapshotKeys)
        }
        return nil
    }
    
    static fileprivate var cacheForKeysFromTheSameObjectThatAffectKeyOfObject : [ AnyClassTuple<KeyPath> : KeySet ] = [:]
    
    static func keysFromTheSameObjectThatAffectKeyOfObject(_ object: NSObject, key: KeyPath) -> KeySet {
        
        let tuple = AnyClassTuple(classOfObject: type(of: object), secondElement: key)
        if let keySet = cacheForKeysFromTheSameObjectThatAffectKeyOfObject[tuple] {
            return keySet
        }
        else {
            
            let keyPathsForValue : KeySet = KeySet((type(of: object).keyPathsForValuesAffectingValue(forKey: key.rawValue)))
            let keyPathsFiltered: [KeyPath] = {
                var filtered: [KeyPath] = []
                for keypath in keyPathsForValue {
                    if let (head, _) = keypath.decompose {
                        filtered.append(head)
                    }
                }
                return filtered
            }()
            
            let keySet = KeySet(keyPathsFiltered)
            cacheForKeysFromTheSameObjectThatAffectKeyOfObject[tuple] = keySet
            return keySet
        }
    }
    
    public var description : String {
        return "SnapshotKeys: \(self.snapshotKeys) \n SnapshotValues: \(self.snapshotValues) \n keysAffectingKeys \(self.keyToAffectedKeys)"
    }
    
    public var debugDescription : String {
        return description
    }
    
}

public func ==(lhs: ObjectSnapshot, rhs: ObjectSnapshot) -> Bool
{
    return lhs.snapshotValues == rhs.snapshotValues
}
