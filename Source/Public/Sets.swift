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
public struct SetGenerator<Element : Hashable> : IteratorProtocol {
    var dictGenerator : DictionaryIterator<Element, Void>
    
    public init(_ d : Dictionary<Element,Void>) {
        dictGenerator = d.makeIterator()
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
    func filter(_ includeElement: (Element) -> Bool)-> Set<Element> {
        return Set(Array(self).filter(includeElement))
    }
    
    func reduce<U>(_ initial: U, combine: (U, Element) -> U) -> U {
        return Array(self).reduce(initial, combine)
    }
    
    /// Returns a set with mapped elements. The resulting set might be smaller than self because
    /// of collisions in the mapping.
    func map<U>(_ transform: (Element) -> U) -> Set<U> {
        return Set<U>(Array(self).map(transform))
    }

    var allObjects: [Element] { return Array(self) }
}

/// Make NSSet more Set like:
extension NSSet {
    public func union(_ s: NSSet) -> NSSet {
        let r = NSMutableSet(set: s)
        r.union(self as Set<NSObject>)
        return r
    }
    public var isEmpty: Bool {
        get {
            return count == 0
        }
    }
}

// MARK: Dictionary
extension Dictionary {
    
    /// Creates a dictionary by applying a function over a sequence, and assigning the calculated value to the sequence element. Also maps the keys
    init<T, S: Sequence>(_ sequence: S, keyMapping: (T) -> Key, valueMapping: (T) -> Value) where S.Iterator.Element == T {
        
        self.init()
        
        for key in sequence {
            let newKey = keyMapping(key)
            let value = valueMapping(key)
            self[newKey] = value
        }
    }

    /// Maps the key keeping the association with values
    func mapKeys<T: Hashable>(_ transform: (Key) -> T) -> [T: Value] {
        var mapping : [T : Value] = [:]
        for (key, value) in self {
            mapping[transform(key)] = value
        }
        return mapping
        
    }
}
