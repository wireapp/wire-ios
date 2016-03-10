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
// along with this program. If not, see <http://www.gnu.org/licenses/>.


import Foundation
import ZMCSystem
import ZMUtilities


/// Map from a key to another
public final class KeyToKeyTransformation {
    
    let mapping : [KeyPath : KeyToKeyMappingType]
    
    public enum KeyToKeyMappingType {
        case Custom(KeyPath)
        case Default
        case None
    }
    
    public init(mapping: [KeyPath : KeyToKeyMappingType]) {
        self.mapping = mapping
    }
    
    func transformKey(key: KeyPath, defaultTransformation: (String) -> String) -> KeyPath? {
        if let transformation = self.mapping[key] {
            switch(transformation) {
            case .Default:
                return KeyPath.keyPathForString(defaultTransformation(key.rawValue))
            case let .Custom(customName):
                return customName
            case .None:
                return nil
            }
        }
        return nil
    }
    
    func allKeys() -> KeySet {
        return KeySet(self.mapping.keys)
    }
    
    func contains(key: KeyPath) -> Bool {
        return self.mapping[key] != nil
    }
    
}

// Objects that need to be in a snapshot should implement this protocol. It will be used to
// set flags on the ObjectChangeInfo
public protocol ObjectInSnapshot : NSObjectProtocol {
    
    // This mapping indicates which keys we should keep track of, and what variable
    // of the final ObjectChangeInfo should be set to true if the value changed
    // e.g. name -> "nameDidChange"
    var keysToChangeInfoMap : KeyToKeyTransformation { get }
    
    // Needed because NSObjectProtocol != NSObject
    func valueForKey(key: String) -> AnyObject?
}

protocol ValueToCopy : NSCopying {}

extension NSOrderedSet : ValueToCopy {}
extension NSSet : ValueToCopy {}

public struct ObjectSnapshot : Equatable, CustomDebugStringConvertible
{
    
    public typealias KeysAndValues = [KeyPath : NSObject]
    public typealias KeysAndOldValues = [KeyPath : NSObject?]
    
    typealias KeysFromTheSameObjectThatAffectKey = [KeyPath : KeySet]

    private let snapshotValues : KeysAndValues
    
    private let snapshotKeys : KeySet
    
    private let keyToAffectedKeys : KeysFromTheSameObjectThatAffectKey // userDefinedName -> displayName, otherActiveParticipants -> displayName, ...
    
    public init(object: NSObject, keys: KeySet) {
        
        self.snapshotKeys = keys
        var snapshotValues : KeysAndValues = [:]
        self.keyToAffectedKeys = ObjectSnapshot.extractKeysAffectingValuesForKeysToSnapshot(object, snapshotKeys: keys)
        
        for key in keys {
            let value: AnyObject? = object.valueForKey(key.rawValue)
            if let nonNilValue: AnyObject = value {
                switch (nonNilValue) {
                    
                case let set as Set<NSObject>:
                    snapshotValues[key] = Set(Array(set)) // This is to materialize potential faults
                    
                case let set as NSOrderedSet:
                    snapshotValues[key] = NSOrderedSet(array: set.array) // This is to materialize potential faults
                    
                case let set as [NSObject]:
                    snapshotValues[key] = set.map { $0 } // This is to materialize potential faults
                
                case let set as NSCopying:
                    if let copy = set.copyWithZone(nil) as? NSObject {
                        snapshotValues[key] = copy
                    } else {
                        fatalError("Can't copy snapshot value for key \(key)")
                    }
                case let objectValue as NSObject:
                    snapshotValues[key] = objectValue
                default:
                    fatalError("Can't snapshot value \(key)")
                }
            }
        }
        self.snapshotValues = snapshotValues
    }
    
    private static func extractKeysAffectingValuesForKeysToSnapshot(object: NSObject, snapshotKeys: KeySet) -> KeysFromTheSameObjectThatAffectKey
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
    
    public func updatedSnapshot(object: NSObject, affectedKeys: AffectedKeys) -> (ObjectSnapshot, KeysAndOldValues)? {
        let keysArray = Array<KeyPath>(self.keyToAffectedKeys.keys)
        let keysThatChangedBecauseAffectedKeysChanged = keysArray.filter { affectedKeys.containsKey($0) }
                                                                 .map { self.keyToAffectedKeys[$0]! }
                                                                 .reduce(KeySet(), combine: {$0.union($1)})
        

        let keysToCheck = self.snapshotKeys.filter { affectedKeys.containsKey($0) }.union(keysThatChangedBecauseAffectedKeysChanged)
        let keysThatChanged : KeySet = keysToCheck.filter { key in
            
            let currentValue = object.valueForKey(key.rawValue) as? NSObject
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
    
    static private var cacheForKeysFromTheSameObjectThatAffectKeyOfObject : [ AnyClassTuple<KeyPath> : KeySet ] = [:]
    
    static func keysFromTheSameObjectThatAffectKeyOfObject(object: NSObject, key: KeyPath) -> KeySet {
        
        let tuple = AnyClassTuple(classOfObject: object.dynamicType, secondElement: key)
        if let keySet = cacheForKeysFromTheSameObjectThatAffectKeyOfObject[tuple] {
            return keySet
        }
        else {
            
            let keyPathsForValue = KeySet(object.dynamicType.keyPathsForValuesAffectingValueForKey(key.rawValue))
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
