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
import WireDataModel

/// A set of instances conforming to `UserType`.

typealias HashBoxUser = HashBox<UserType>

// MARK: - UserSet

struct UserSet {
    // MARK: Internal

    typealias Storage = Set<HashBoxUser>

    // MARK: Private

    private var storage: Storage
}

// MARK: Collection

extension UserSet: Collection {
    typealias Element = UserType
    typealias Index = Storage.Index

    var isEmpty: Bool {
        storage.isEmpty
    }

    var startIndex: Index {
        storage.startIndex
    }

    var endIndex: Index {
        storage.endIndex
    }

    func index(after i: Index) -> Index {
        storage.index(after: i)
    }

    subscript(position: Index) -> UserType {
        storage[position].value
    }

    __consuming func makeIterator() -> IndexingIterator<[UserType]> {
        storage.map(\.value).makeIterator()
    }
}

// MARK: SetAlgebra

extension UserSet: SetAlgebra {
    init() {
        self.storage = Storage()
    }

    init(arrayLiteral elements: UserType...) {
        self.storage = Storage(elements.map(HashBox.init))
    }

    func contains(_ member: UserType) -> Bool {
        storage.contains(HashBox(value: member))
    }

    __consuming func union(_ other: __owned UserSet) -> UserSet {
        UserSet(storage: storage.union(other.storage))
    }

    __consuming func intersection(_ other: UserSet) -> UserSet {
        UserSet(storage: storage.intersection(other.storage))
    }

    __consuming func symmetricDifference(_ other: __owned UserSet) -> UserSet {
        UserSet(storage: storage.symmetricDifference(other.storage))
    }

    @discardableResult
    mutating func insert(_ newMember: __owned UserType) -> (inserted: Bool, memberAfterInsert: UserType) {
        let (inserted, memberAfterInsert) = storage.insert(HashBox(value: newMember))
        return (inserted, memberAfterInsert.value)
    }

    @discardableResult
    mutating func remove(_ member: UserType) -> UserType? {
        storage.remove(HashBox(value: member))?.value
    }

    @discardableResult
    mutating func update(with newMember: __owned UserType) -> UserType? {
        storage.update(with: HashBox(value: newMember))?.value
    }

    mutating func formUnion(_ other: __owned UserSet) {
        storage.formUnion(other.storage)
    }

    mutating func formIntersection(_ other: UserSet) {
        storage.formIntersection(other.storage)
    }

    mutating func formSymmetricDifference(_ other: __owned UserSet) {
        storage.formSymmetricDifference(other.storage)
    }
}
