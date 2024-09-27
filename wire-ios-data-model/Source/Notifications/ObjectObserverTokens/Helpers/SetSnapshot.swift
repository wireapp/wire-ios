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

// MARK: - SetStateUpdate

public struct SetStateUpdate<T: Hashable> {
    // MARK: Public

    public let newSnapshot: SetSnapshot<T>
    public let changeInfo: SetChangeInfo<T>

    // MARK: Internal

    let removedObjects: Set<T>
    let insertedObjects: Set<T>
}

// MARK: - SetChangeInfoOwner

public protocol SetChangeInfoOwner {
    associatedtype ChangeInfoContent: Hashable
    var orderedSetState: OrderedSetState<ChangeInfoContent> { get }
    var setChangeInfo: SetChangeInfo<ChangeInfoContent> { get }
    var insertedIndexes: IndexSet { get }
    var deletedIndexes: IndexSet { get }
    var deletedObjects: Set<AnyHashable> { get }
    var updatedIndexes: IndexSet { get }
    var movedIndexPairs: [MovedIndex] { get }
    var zm_movedIndexPairs: [ZMMovedIndex] { get }

    func enumerateMovedIndexes(_ block: @escaping (_ from: Int, _ to: Int) -> Void)
}

// MARK: - SetChangeInfo

open class SetChangeInfo<T: Hashable>: NSObject {
    // MARK: Lifecycle

    convenience init(observedObject: NSObject) {
        let orderSetState = OrderedSetState<T>(array: [])
        self.init(
            observedObject: observedObject,
            changeSet: ChangedIndexes(start: orderSetState, end: orderSetState, updated: Set()),
            orderedSetState: orderSetState
        )
    }

    public init(observedObject: NSObject, changeSet: ChangedIndexes<T>, orderedSetState: OrderedSetState<T>) {
        self.changeSet = changeSet
        self.orderedSetState = orderedSetState
        self.observedObject = observedObject
    }

    // MARK: Open

    open var insertedIndexes: IndexSet { changeSet.insertedIndexes }
    open var deletedIndexes: IndexSet { changeSet.deletedIndexes }
    open var deletedObjects: Set<AnyHashable> { changeSet.deletedObjects }
    open var updatedIndexes: IndexSet { changeSet.updatedIndexes }
    open var movedIndexPairs: [MovedIndex] { changeSet.movedIndexes }
    // for temporary objC-compatibility
    open var zm_movedIndexPairs: [ZMMovedIndex] { changeSet.movedIndexes.map { ZMMovedIndex(
        from: UInt($0.from),
        to: UInt($0.to)
    ) } }
    override open var description: String { debugDescription }
    override open var debugDescription: String {
        "deleted: \(deletedIndexes), inserted: \(insertedIndexes), " +
            "updated: \(updatedIndexes), moved: \(movedIndexPairs)"
    }

    open func enumerateMovedIndexes(_ block: @escaping (_ from: Int, _ to: Int) -> Void) {
        changeSet.enumerateMovedIndexes(block: block)
    }

    // MARK: Public

    public let orderedSetState: OrderedSetState<T>

    public let observedObject: NSObject

    // MARK: Internal

    let changeSet: ChangedIndexes<T>
}

// MARK: - SetSnapshot

public struct SetSnapshot<T: Hashable> {
    // MARK: Lifecycle

    public init(set: OrderedSetState<T>, moveType: SetChangeMoveType) {
        self.set = set
        self.moveType = moveType
    }

    // MARK: Public

    public let set: OrderedSetState<T>
    public let moveType: SetChangeMoveType

    // Returns the new state and the notification to send after some changes in messages
    public func updatedState(
        _ updatedObjects: Set<T>,
        observedObject: NSObject,
        newSet: OrderedSetState<T>
    ) -> SetStateUpdate<T>? {
        if set == newSet, updatedObjects.isEmpty {
            return nil
        }

        let changeSet = ChangedIndexes(start: set, end: newSet, updated: updatedObjects, moveType: moveType)
        let changeInfo = SetChangeInfo(observedObject: observedObject, changeSet: changeSet, orderedSetState: newSet)

        if changeInfo.insertedIndexes.isEmpty, changeInfo.deletedIndexes.isEmpty,
           changeInfo.updatedIndexes.isEmpty, changeInfo.movedIndexPairs.isEmpty {
            return nil
        }
        return SetStateUpdate(
            newSnapshot: SetSnapshot(set: newSet, moveType: moveType),
            changeInfo: changeInfo,
            removedObjects: changeSet.deletedObjects,
            insertedObjects: changeSet.insertedObjects
        )
    }
}
