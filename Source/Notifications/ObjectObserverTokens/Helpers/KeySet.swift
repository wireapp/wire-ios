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
// along with this program. If not, see <http://www.gnu.org/licenses/>.
// 


import Foundation
import ZMUtilities


public struct KeySet : SequenceType {
    public typealias Key = KeyPath
    public typealias Generator = Set<KeyPath>.Generator
    private let backing: Set<KeyPath>
    
    public init() {
        backing = Set()
    }
    
    public init(_ set : NSSet) {
        var a: [KeyPath] = []
        for s in set {
            if let ss = s as? String {
                a.append(KeyPath.keyPathForString(ss))
            } else {
                fatalError("\(s) is not a string")
            }
        }
        backing = Set(a)
    }
    public init (_ set : Set<Key>) {
        backing = set
    }
    
    public init(_ a : [String]) {
        var aa: [KeyPath] = []
        for s in a {
            aa.append(KeyPath.keyPathForString(s))
        }
        backing = Set<KeyPath>(aa)
    }
    public init(key: KeyPath) {
        self.init(Set([key]))
    }
    public init(keyPaths: [KeyPath]) {
        self.init(Set(keyPaths))
    }
    public init(key: String) {
        self.init(Set([KeyPath.keyPathForString(key)]))
    }
    public init(arrayLiteral elements: String...) {
        self.init(elements)
    }
    init<S : SequenceType where S.Generator.Element == Key>(_ seq: S) {
        backing = Set<Key>(seq)
    }
    public func contains(i : KeyPath) -> Bool {
        return backing.contains(i)
    }
    public func contains(i : String) -> Bool {
        return backing.contains(KeyPath.keyPathForString(i))
    }
    public func generate() -> Set<KeyPath>.Generator {
        return backing.generate()
    }
}

extension KeySet : Hashable {
    public var hashValue: Int {
        return backing.hashValue
    }
}

public func ==(lhs: KeySet, rhs: KeySet) -> Bool {
    return lhs.backing == rhs.backing
}


extension KeySet {
    func union(set: KeySet) -> KeySet {
        return KeySet(backing.union(set.backing))
    }
    func subtract(set: KeySet) -> KeySet {
        return KeySet(backing.subtract(set.backing))
    }
    public var isEmpty: Bool {
        return backing.isEmpty
    }
    func filter(match: (KeyPath) -> Bool) -> KeySet {
        return KeySet(backing.filter {match($0)})
    }
}

extension KeySet : CustomDebugStringConvertible {
    public var description: String {
        let a = Array<KeyPath>(backing)
        let ss = a.map { $0.rawValue }.sort() {
            (lhs, rhs) in lhs < rhs
        }
        return "KeySet {" + ss.joinWithSeparator(" ") + "}"
    }
    public var debugDescription: String {
        return description
    }
}
