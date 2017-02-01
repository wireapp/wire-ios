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

public extension NSOrderedSet {
    
    public func subtracting(orderedSet: NSOrderedSet) -> NSOrderedSet {
        let mutableSelf = mutableCopy() as! NSMutableOrderedSet
        mutableSelf.minus(orderedSet)
        return NSOrderedSet(orderedSet: mutableSelf)
    }
    
    public func adding(orderedSet: NSOrderedSet) -> NSOrderedSet {
        let mutableSelf = mutableCopy() as! NSMutableOrderedSet
        mutableSelf.union(orderedSet)
        return NSOrderedSet(orderedSet: mutableSelf)
    }
}

public struct SetStateUpdate {
    
    public let newSnapshot : SetSnapshot
    public let changeInfo : SetChangeInfo
    
    let removedObjects : NSOrderedSet
    let insertedObjects : NSOrderedSet

}

@objc open class SetChangeInfo : NSObject {
    
    let changeSet : ZMChangedIndexes
    open let observedObject : NSObject
    open var insertedIndexes : IndexSet { return changeSet.insertedIndexes }
    open var deletedIndexes : IndexSet { return changeSet.deletedIndexes }
    open var deletedObjects: Set<AnyHashable> { return changeSet.deletedObjects }
    open var updatedIndexes : IndexSet { return changeSet.updatedIndexes }
    open var needsReload : Bool { return changeSet.requiresReload }
    
    convenience init(observedObject: NSObject) {
        let orderSetState = ZMOrderedSetState(orderedSet: NSOrderedSet())
        self.init(observedObject: observedObject, changeSet: ZMChangedIndexes(start: orderSetState, end: orderSetState, updatedState: orderSetState))
    }
    
    public init(observedObject: NSObject, changeSet: ZMChangedIndexes) {
        self.changeSet = changeSet
        self.observedObject = observedObject
    }

    open var movedIndexPairs : [ZMMovedIndex] {
        var array : [ZMMovedIndex] = []
        self.changeSet.enumerateMovedIndexes  {(x: UInt, y: UInt) in array.append(ZMMovedIndex(from: x, to: y)) }
        return array
    }
    
    open func enumerateMovedIndexes(_ block:@escaping (_ from: UInt, _ to : UInt) -> Void) {
        self.changeSet.enumerateMovedIndexes(block)
    }
    
    open override var description : String { return self.debugDescription }
    open override var debugDescription : String {
        return "deleted: \(deletedIndexes), inserted: \(insertedIndexes), " +
        "updated: \(updatedIndexes), moved: \(movedIndexPairs)"
    }

}

public struct SetSnapshot {
    
    public let set : NSOrderedSet
    public let moveType : ZMSetChangeMoveType
    
    public init(set: NSOrderedSet, moveType : ZMSetChangeMoveType) {
        self.set = set.copy() as! NSOrderedSet
        self.moveType = moveType
    }
    
    fileprivate func calculateChangeSet(_ newSet: NSOrderedSet, updatedObjects: NSOrderedSet) -> ZMChangedIndexes {
        let startState = ZMOrderedSetState(orderedSet:self.set)
        let endState = ZMOrderedSetState(orderedSet:newSet)
        let updatedState = ZMOrderedSetState(orderedSet:updatedObjects)
        
        return ZMChangedIndexes(start:startState, end:endState, updatedState:updatedState, moveType:self.moveType)
    }
    
    // Returns the new state and the notification to send after some changes in messages
    public func updatedState(_ updatedObjects: NSOrderedSet, observedObject: NSObject, newSet: NSOrderedSet) -> SetStateUpdate? {
    
        if self.set == newSet && updatedObjects.count == 0 {
            return nil
        }
        
        let changeSet = self.calculateChangeSet(newSet.copy() as! NSOrderedSet, updatedObjects: updatedObjects)
        let changeInfo = SetChangeInfo(observedObject: observedObject, changeSet: changeSet)

        let insertedObjects = newSet.subtracting(orderedSet: set)
        let removedObjects = set.subtracting(orderedSet: newSet)
        
        if changeInfo.insertedIndexes.count == 0 && changeInfo.deletedIndexes.count == 0 && changeInfo.updatedIndexes.count == 0 && changeInfo.movedIndexPairs.count == 0 {
            return nil
        }
        return SetStateUpdate(newSnapshot: SetSnapshot(set: newSet, moveType: self.moveType), changeInfo: changeInfo, removedObjects: removedObjects, insertedObjects: insertedObjects)
    }
}
