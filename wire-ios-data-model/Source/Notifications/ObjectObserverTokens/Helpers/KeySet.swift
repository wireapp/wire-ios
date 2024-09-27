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

// MARK: - AffectedKeys

public enum AffectedKeys: Equatable {
    case some(KeySet)
    case all

    func combinedWith(_ other: AffectedKeys) -> AffectedKeys {
        switch (self, other) {
        case let (.some(k1), .some(k2)):
            .some(k1.union(k2))
        default:
            .all
        }
    }

    func containsKey(_ key: StringKeyPath) -> Bool {
        switch self {
        case let .some(keySet):
            keySet.contains(key)
        case .all:
            true
        }
    }
}

public func == (lhs: AffectedKeys, rhs: AffectedKeys) -> Bool {
    switch (lhs, rhs) {
    case let (.some(lk), .some(rk)):
        lk == rk
    case (.all, .all):
        true
    default:
        false
    }
}

// MARK: - KeySet

public struct KeySet: Sequence {
    public typealias Key = StringKeyPath
    public typealias Iterator = Set<StringKeyPath>.Iterator
    fileprivate let backing: Set<StringKeyPath>

    public init() {
        self.backing = Set()
    }

    public init(_ set: NSSet) {
        var a: [StringKeyPath] = []
        for s in set {
            if let ss = s as? String {
                a.append(StringKeyPath.keyPathForString(ss))
            } else {
                fatal("\(type(of: s)) is not a string")
            }
        }
        self.backing = Set(a)
    }

    public init(_ set: Set<Key>) {
        self.backing = set
    }

    public init(_ keys: Set<String>) {
        self.init(Array(keys))
    }

    public init(_ a: [String]) {
        var aa: [StringKeyPath] = []
        for s in a {
            aa.append(StringKeyPath.keyPathForString(s))
        }
        self.backing = Set<StringKeyPath>(aa)
    }

    public init(key: StringKeyPath) {
        self.init(Set([key]))
    }

    public init(keyPaths: [StringKeyPath]) {
        self.init(Set(keyPaths))
    }

    public init(key: String) {
        self.init(Set([StringKeyPath.keyPathForString(key)]))
    }

    public init(arrayLiteral elements: String...) {
        self.init(elements)
    }

    init<S: Sequence>(_ seq: S) where S.Iterator.Element == Key {
        self.backing = Set<Key>(seq)
    }

    public func contains(_ i: StringKeyPath) -> Bool {
        backing.contains(i)
    }

    public func contains(_ i: String) -> Bool {
        backing.contains(StringKeyPath.keyPathForString(i))
    }

    public func makeIterator() -> Set<StringKeyPath>.Iterator {
        backing.makeIterator()
    }

    public var count: Int {
        backing.count
    }
}

// MARK: Hashable

extension KeySet: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(backing.hashValue)
    }
}

public func == (lhs: KeySet, rhs: KeySet) -> Bool {
    lhs.backing == rhs.backing
}

extension KeySet {
    func union(_ set: KeySet) -> KeySet {
        KeySet(backing.union(set.backing))
    }

    func subtract(_ set: KeySet) -> KeySet {
        KeySet(backing.subtracting(set.backing))
    }

    public var isEmpty: Bool {
        backing.isEmpty
    }

    func filter(_ match: (StringKeyPath) -> Bool) -> KeySet {
        KeySet(backing.filter { match($0) })
    }
}

// MARK: CustomDebugStringConvertible

extension KeySet: CustomDebugStringConvertible {
    public var description: String {
        let a = [StringKeyPath](backing)
        let ss = a.map(\.rawValue).sorted { lhs, rhs in lhs < rhs }
        return "KeySet {" + ss.joined(separator: " ") + "}"
    }

    public var debugDescription: String {
        description
    }
}
