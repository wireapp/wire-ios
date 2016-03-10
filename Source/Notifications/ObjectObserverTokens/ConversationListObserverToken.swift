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
import ZMCSystem

extension ZMConversationList {
    
    func toOrderedSet() -> OrderedSet<NSObject> {
        var array : [ZMConversation] = []
        for conv in self {
            array.append(conv as! ZMConversation)
        }
        return OrderedSet<NSObject>(array: array)
    }
    
}



@objc public final class ConversationListChangeInfo : SetChangeInfo, CustomDebugStringConvertible {
    
    public var conversationList : ZMConversationList { return self.observedObject as! ZMConversationList }
    
    init(setChangeInfo: SetChangeInfo) {
        super.init(observedObject: setChangeInfo.observedObject, changeSet: setChangeInfo.changeSet)
    }
}

final class ConversationListObserverToken: NSObject {
    
    private var state : SetSnapshot
    
    let conversationList : ZMConversationList
    
    private weak var observer : ZMConversationListObserver?
    
    init(conversationList: ZMConversationList, observer: ZMConversationListObserver?) {
        
        self.conversationList = conversationList
        self.observer = observer
        #if os(iOS)
            let moveType: ZMSetChangeMoveType = .UICollectionView
        #else
            let moveType: ZMSetChangeMoveType = .NSTableView
        #endif
        self.state = SetSnapshot(set: conversationList.toOrderedSet(), moveType: moveType)
        super.init()
    }
    
    func notifyObserver(changedConversation: ZMConversation?, changes: ConversationChangeInfo?) {
        
        let changedSet : OrderedSet<NSObject> = changedConversation == nil ? OrderedSet() : OrderedSet(object: changedConversation!)
        let newSet = self.conversationList.toOrderedSet()
        
        if let newStateUpdate = self.state.updatedState(changedSet, observedObject: self.conversationList, newSet: newSet) {
            self.state = newStateUpdate.newSnapshot
            let conversationListChangeInfo = ConversationListChangeInfo(setChangeInfo: newStateUpdate.changeInfo)
            self.observer?.conversationListDidChange(conversationListChangeInfo)
            
        }
        if let changes = changes {
            self.observer?.conversationInsideList?(self.conversationList, didChange: changes)
        }
    }

}

