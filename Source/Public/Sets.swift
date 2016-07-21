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
import Swift


/// START https://gist.github.com/anonymous/9bb5f5d9f6918b1482b6
/// Taken from that gist & slightly adapted.
public struct SetGenerator<Element : Hashable> : GeneratorType {
    var dictGenerator : DictionaryGenerator<Element, Void>
    
    public init(_ d : Dictionary<Element,Void>) {
        dictGenerator = d.generate()
    }
    
    public mutating func next() -> Element? {
        if let tuple = dictGenerator.next() {
            let (k, _) = tuple
            return k
        } else {
            return nil
        }
    }
}

// MARK: Set
extension Set {
    
    /// Returns a set with elements filtered out
    func filter(includeElement: (Element) -> Bool)-> Set<Element> {
        return Set(Array(self).filter(includeElement))
    }
    
    func reduce<U>(initial: U, combine: (U, Element) -> U) -> U {
        return Array(self).reduce(initial, combine: combine)
    }
    
    /// Returns a set with mapped elements. The resulting set might be smaller than self because
    /// of collisions in the mapping.
    func map<U>(transform: (Element) -> U) -> Set<U> {
        return Set<U>(Array(self).map(transform))
    }

    var allObjects: [Element] { return Array(self) }
}

/// Make NSSet more Set like:
extension NSSet {
    public func union(s: NSSet) -> NSSet {
        let r = NSMutableSet(set: s)
        r.unionSet(self as Set<NSObject>)
        return r
    }
    public var isEmpty: Bool {
        get {
            return count == 0
        }
    }
    public func contains(obj: NSObject) -> Bool {
        return self.containsObject(obj)
    }

}

// MARK: OrderedSet
public final class OrderedSet<T  where T : NSObject, T : Hashable> : Equatable, SequenceType {
    
    private let innerSet : NSOrderedSet
    
    public func toNSOrderedSet() -> NSOrderedSet {
        return self.innerSet.copy() as! NSOrderedSet
    }
    
    public func generate() -> AnyGenerator<T> {
        let enumeration = self.innerSet.objectEnumerator()
        
        return AnyGenerator {
            return enumeration.nextObject() as? T
        }
    }
    
    public var count : Int {
        return self.innerSet.count
    }
    
    public init() {
        self.innerSet = NSOrderedSet()
    }
    
    public init(array: [T]) {
        self.innerSet = NSOrderedSet(array: array)
    }
    
    public init(object: T) {
        self.innerSet = NSOrderedSet(object: object)
    }
    
    public init(orderedSet: NSOrderedSet) {
        self.innerSet = orderedSet.copy() as! NSOrderedSet
    }
    
    public init(set: OrderedSet<T>) {
        self.innerSet = set.innerSet.copy() as! NSOrderedSet
    }
    
    public func minus(set: OrderedSet<T>) -> OrderedSet<T> {
        let mutableInnerset = self.innerSet.mutableCopy() as! NSMutableOrderedSet
        mutableInnerset.minusOrderedSet(set.innerSet)
        return OrderedSet<T>(orderedSet: mutableInnerset)
    }
    
    public func union(set: OrderedSet<T>) -> OrderedSet<T> {
        let mutableInnerset = self.innerSet.mutableCopy() as! NSMutableOrderedSet
        mutableInnerset.unionOrderedSet(set.innerSet)
        return OrderedSet<T>(orderedSet: mutableInnerset)
    }
    
    public func set() -> Set<T> {
        return Set(self.innerSet.array as! [T])
    }
    public var array: [T] {
        get {
            return self.innerSet.array as! [T]
        }
    }
}

public func ==<T>(lhs : OrderedSet<T>, rhs : OrderedSet<T>) -> Bool {
    return lhs.innerSet.isEqualToOrderedSet(rhs.innerSet)
}

// MARK: Dictionary
extension Dictionary {

    // Does not compile with Swift 1.1
//    /// Creates a dictionary by applying a function over a sequence, and assigning the calculated value to the sequence element
//    init<S: SequenceType where S.Generator.Element == Key>(_ sequence: S, valueMapping: (Key) -> Value) {
//        
//        self.init()
//        var dict : [Key:Value] = [:]
//        
//        for key in sequence {
//            let value = valueMapping(key)
//            self[key] = value
//        }
//    }
    
    
    /// Creates a dictionary by applying a function over a sequence, and assigning the calculated value to the sequence element. Also maps the keys
    init<T, S: SequenceType where S.Generator.Element == T>(_ sequence: S, keyMapping: (T) -> Key, valueMapping: (T) -> Value) {
        
        self.init()
        
        for key in sequence {
            let newKey = keyMapping(key)
            let value = valueMapping(key)
            self[newKey] = value
        }
    }

    /// Maps the key keeping the association with values
    func mapKeys<T: Hashable>(transform: (Key) -> T) -> [T: Value] {
        var mapping : [T : Value] = [:]
        for (key, value) in self {
            mapping[transform(key)] = value
        }
        return mapping
        
    }
}
