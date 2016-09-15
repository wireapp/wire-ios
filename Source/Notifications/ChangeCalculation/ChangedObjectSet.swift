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




public enum AffectedKeys : Equatable {
    case some(KeySet)
    case all

    func combinedWith(_ other: AffectedKeys) -> AffectedKeys {
        switch (self, other) {
        case let (.some(k1), .some(k2)):
            return .some(k1.union(k2))
        default:
            return .all
        }
    }
    
    func containsKey(_ key: KeyPath) -> Bool {
        switch(self) {
        case let .some(keySet):
            return keySet.contains(key)
        case .all:
            return true
        }
    }
}

public struct ChangedObjectSet : Equatable {
    
    public typealias ChangedObject = NSObject
    
    public struct ObjectWithKeys : Equatable {
        public let object: ChangedObject
        public let keys: AffectedKeys
        
        public init(object: ChangedObject, keys: AffectedKeys){
            self.object = object
            self.keys = keys
        }
    }

    let elements: [ChangedObject: AffectedKeys]
    
    public init() {
        self.elements = [:]
    }
    
    public init(element: ChangedObject, affectedKeys: AffectedKeys = AffectedKeys.all) {
        self.elements = [element: affectedKeys]
    }

    public init(notification: Notification) {
        var tempElements : [ChangedObject: AffectedKeys] = [:]
        for changeKey in [NSUpdatedObjectsKey, NSRefreshedObjectsKey] {
            if let objectSet = notification.userInfo?[changeKey] as! NSSet? {
                for object in objectSet {
                    tempElements[object as! ChangedObject] = AffectedKeys.all
                }
            }
        }
        self.init(elements: tempElements)
    }
    
    init(elements: [ChangedObject: AffectedKeys]) {
        self.elements = elements
    }
    
    public func decompose() -> (head: ObjectWithKeys, tail: ChangedObjectSet)? {
        // Using Dictionary.decompose() crashes the compiler. Using this for now. <rdar://problem/19516565>
        if let key = elements.keys.first {
            let head = ObjectWithKeys(object:key, keys: elements[key]!)
            var tail = elements
            tail.removeValue(forKey: key)
            return ((head), ChangedObjectSet(elements: tail))
        } else {
            return nil
        }
    }
    
    public func unionWithSet(_ other: ChangedObjectSet) -> ChangedObjectSet {
        var newElements = self.elements
        for (element, keys2) in other.elements {
            if let keys1 = newElements[element] {
                newElements[element] = keys2.combinedWith(keys1)
            } else {
                newElements[element] = keys2
            }
        }
        return ChangedObjectSet(elements: newElements)
    }
}


// MARK: - Equatable

public func ==(lhs: ChangedObjectSet, rhs: ChangedObjectSet) -> Bool {
    return lhs.elements == rhs.elements
}

public func ==(lhs: (ChangedObjectSet.ChangedObject, AffectedKeys), rhs: (ChangedObjectSet.ChangedObject, AffectedKeys)) -> Bool {
    return (lhs.0 == rhs.0) && (lhs.1 == rhs.1)
}

public func ==(lhs: ChangedObjectSet.ObjectWithKeys, rhs: ChangedObjectSet.ObjectWithKeys) -> Bool {
    return (lhs.object == rhs.object) && (lhs.keys == rhs.keys)
}

public func ==(lhs: AffectedKeys, rhs: AffectedKeys) -> Bool {
    switch (lhs, rhs) {
    case let (.some(lk), .some(rk)):
        return lk == rk
    case (.all, .all):
        return true
    default:
        return false
    }
}

// MARK: - Generator / SequenceType

extension ChangedObjectSet : Sequence {
    
    public typealias Iterator = ChangedObjectSetGenerator
    public func makeIterator() -> Iterator {
        return ChangedObjectSetGenerator(set: self)
    }
    
    public struct ChangedObjectSetGenerator : IteratorProtocol {
        public typealias Element = ChangedObjectSet.ObjectWithKeys
        
        init(set: ChangedObjectSet) {
            remainder = set
        }
        var remainder: ChangedObjectSet
        
        public mutating func next() -> Element? {
            if let (head, tail) = remainder.decompose() {
                remainder = tail
                return head
            }
            return nil
        }
    }
}
