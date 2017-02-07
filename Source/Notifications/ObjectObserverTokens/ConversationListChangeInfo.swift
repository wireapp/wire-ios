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
import ZMCSystem

extension ZMConversationList {
    
    func toOrderedSet() -> NSOrderedSet {
        return NSOrderedSet(array: self.map{$0})
    }
    
}

@objc public final class ConversationListChangeInfo : SetChangeInfo {
    
    public var conversationList : ZMConversationList { return self.observedObject as! ZMConversationList }
    
    init(setChangeInfo: SetChangeInfo) {
        super.init(observedObject: setChangeInfo.observedObject, changeSet: setChangeInfo.changeSet)
    }
}



@objc public protocol ZMConversationListObserver : NSObjectProtocol {
    func conversationListDidChange(_ changeInfo: ConversationListChangeInfo)
    @objc optional func conversationInsideList(_ list: ZMConversationList, didChange changeInfo: ConversationChangeInfo)
}

extension ConversationListChangeInfo {

    /// Adds a ZMConversationListObserver to the specified list
    /// You must hold on to the token and use it to unregister
    @objc(addObserver:forList:)
    public static func add(observer: ZMConversationListObserver,for list: ZMConversationList) -> NSObjectProtocol {
        return NotificationCenterObserverToken(name: .ZMConversationListDidChange, object: list)
        { [weak observer] (note) in
            guard let `observer` = observer, let list = note.object as? ZMConversationList
                else { return }
            
            if let changeInfo = note.userInfo?["conversationListChangeInfo"] as? ConversationListChangeInfo{
                observer.conversationListDidChange(changeInfo)
            }
            if let changeInfos = note.userInfo?["conversationChangeInfos"] as? [ConversationChangeInfo] {
                changeInfos.forEach{
                    observer.conversationInsideList?(list, didChange: $0)
                }
            }
        }
    }
    
    @objc(removeObserver:forList:)
    public static func remove(observer: NSObjectProtocol, for list: ZMConversationList?) {
        guard let token = (observer as? NotificationCenterObserverToken)?.token else {
            NotificationCenter.default.removeObserver(observer, name: .ZMConversationListDidChange, object: list)
            return
        }
        NotificationCenter.default.removeObserver(token, name: .ZMConversationListDidChange, object: list)
    }
}
