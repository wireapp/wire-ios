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

struct SetStateUpdate {
    
    let newSnapshot : SetSnapshot
    let changeInfo : SetChangeInfo
    
    let removedObjects : OrderedSet<NSObject>
    let insertedObjects : OrderedSet<NSObject>

}

@objc public class SetChangeInfo : NSObject {
    
    let changeSet : ZMChangedIndexes
    public let observedObject : NSObject
    public var insertedIndexes : NSIndexSet { return changeSet.insertedIndexes }
    public var deletedIndexes : NSIndexSet { return changeSet.deletedIndexes }
    public var deletedObjects: NSSet { return changeSet.deletedObjects }
    public var updatedIndexes : NSIndexSet { return changeSet.updatedIndexes }
    public var needsReload : Bool { return changeSet.requiresReload }
    
    convenience init(observedObject: NSObject) {
        let orderSetState = ZMOrderedSetState(orderedSet: NSOrderedSet())
        self.init(observedObject: observedObject, changeSet: ZMChangedIndexes(startState: orderSetState, endState: orderSetState, updatedState: orderSetState))
    }
    
    public init(observedObject: NSObject, changeSet: ZMChangedIndexes) {
        self.changeSet = changeSet
        self.observedObject = observedObject
    }

    public var movedIndexPairs : [ZMMovedIndex] {
        var array : [ZMMovedIndex] = []
        self.changeSet.enumerateMovedIndexes  {(x: UInt, y: UInt) in array.append(ZMMovedIndex(from: x, to: y)) }
        return array
    }
    
    public func enumerateMovedIndexes(block:(from: UInt, to : UInt) -> Void) {
        self.changeSet.enumerateMovedIndexes(block)
    }
    
    public override var description : String { return self.debugDescription }
    public override var debugDescription : String {
        return "deleted: \(deletedIndexes), inserted: \(insertedIndexes), " +
        "updated: \(updatedIndexes), moved: \(movedIndexPairs)"
    }

}

 struct SetSnapshot {
    
    let set : OrderedSet<NSObject>
    let moveType : ZMSetChangeMoveType
    
    init(set: OrderedSet<NSObject>,  moveType : ZMSetChangeMoveType) {
        self.set = set
        self.moveType = moveType
    }
    
    private func calculateChangeSet(newSet: OrderedSet<NSObject>, updatedObjects: OrderedSet<NSObject>) -> ZMChangedIndexes {
        let startState = ZMOrderedSetState(orderedSet:self.set.toNSOrderedSet())
        let endState = ZMOrderedSetState(orderedSet:newSet.toNSOrderedSet())
        let updatedState = ZMOrderedSetState(orderedSet:updatedObjects.toNSOrderedSet())
        
        return ZMChangedIndexes(startState:startState, endState:endState, updatedState:updatedState, moveType:self.moveType)
    }
    
    // Returns the new state and the notification to send after some changes in messages
    func updatedState(updatedObjects: OrderedSet<NSObject>, observedObject: NSObject, newSet: OrderedSet<NSObject>) -> SetStateUpdate? {
    
        if self.set == newSet && updatedObjects.count == 0 {
            return nil
        }
        
        let changeSet = self.calculateChangeSet(newSet, updatedObjects: updatedObjects)
        let changeInfo = SetChangeInfo(observedObject: observedObject, changeSet: changeSet)
        
        let insertedObjects = newSet.minus(self.set)
        let removedObjects = self.set.minus(newSet)
        
        if changeInfo.insertedIndexes.count == 0 && changeInfo.deletedIndexes.count == 0 && changeInfo.updatedIndexes.count == 0 && changeInfo.movedIndexPairs.count == 0 {
            return nil
        }
        return SetStateUpdate(newSnapshot: SetSnapshot(set: newSet, moveType: self.moveType), changeInfo: changeInfo, removedObjects: removedObjects, insertedObjects: insertedObjects)
    }
}
