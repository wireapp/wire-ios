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




public enum AffectedKeys : Equatable {
    case Some(KeySet)
    case All

    func combinedWith(other: AffectedKeys) -> AffectedKeys {
        switch (self, other) {
        case let (.Some(k1), .Some(k2)):
            return .Some(k1.union(k2))
        default:
            return .All
        }
    }
    
    func containsKey(key: KeyPath) -> Bool {
        switch(self) {
        case let .Some(keySet):
            return keySet.contains(key)
        case .All:
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
    
    public init(element: ChangedObject, affectedKeys: AffectedKeys = AffectedKeys.All) {
        self.elements = [element: affectedKeys]
    }

    public init(notification: NSNotification) {
        var tempElements : [ChangedObject: AffectedKeys] = [:]
        for changeKey in [NSUpdatedObjectsKey, NSRefreshedObjectsKey] {
            if let objectSet = notification.userInfo?[changeKey] as! NSSet? {
                for object in objectSet {
                    tempElements[object as! ChangedObject] = AffectedKeys.All
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
            tail.removeValueForKey(key)
            return ((head), ChangedObjectSet(elements: tail))
        } else {
            return nil
        }
    }
    
    public func unionWithSet(other: ChangedObjectSet) -> ChangedObjectSet {
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
    case let (.Some(lk), .Some(rk)):
        return lk == rk
    case (.All, .All):
        return true
    default:
        return false
    }
}

// MARK: - Generator / SequenceType

extension ChangedObjectSet : SequenceType {
    
    public typealias Generator = ChangedObjectSetGenerator
    public func generate() -> Generator {
        return ChangedObjectSetGenerator(set: self)
    }
    
    public struct ChangedObjectSetGenerator : GeneratorType {
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
