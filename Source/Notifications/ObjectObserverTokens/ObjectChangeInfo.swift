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


/// MARK: Base class for observer / change info
public protocol ObjectChangeInfoProtocol : NSObjectProtocol {
    
    init(object: NSObject)
    func setValue(_ value: Any?, forKey key: String)
    func value(forKey key: String) -> Any?
    var changeInfos : [String : NSObject?] {get set}

}

open class ObjectChangeInfo : NSObject, ObjectChangeInfoProtocol {
    
    let object : NSObject
    
    public required init(object: NSObject) {
        self.object = object
    }
    open var changedKeys : Set<String> = Set()
    open var changeInfos : [String : NSObject?] = [:]
    
    
    func changedKeysContain(keys: String...) -> Bool {
        return !changedKeys.isDisjoint(with: keys)
    }
    
    var customDebugDescription : String {
        guard let managedObject = object as? NSManagedObject else {
            return "ChangeInfo for \(object) with changedKeys: \(changedKeys), changeInfos: \(changeInfos)"
        }
        return "ChangeInfo for \(managedObject.objectID) with changedKeys: \(changedKeys), changeInfos: \(changeInfos)"
    }
}



extension ObjectChangeInfo {
    
    static func changeInfo(for object: NSObject, changes: Changes) -> ObjectChangeInfo? {
        switch object {
        case let object as ZMConversation:  return ConversationChangeInfo.changeInfo(for: object, changes: changes)
        case let object as ZMUser:          return UserChangeInfo.changeInfo(for: object, changes: changes)
        case let object as ZMMessage:       return MessageChangeInfo.changeInfo(for: object, changes: changes)
        case let object as UserClient:      return UserClientChangeInfo.changeInfo(for: object, changes: changes)
        case let object as Team:            return TeamChangeInfo.changeInfo(for: object, changes: changes)
        default:
            return nil
        }
    }
    
    static func changeInfoForNewMessageNotification(with name: Notification.Name, changedMessages messages: Set<ZMMessage>) -> ObjectChangeInfo? {
        switch name {
        case Notification.Name.NewUnreadUnsentMessage:
            return NewUnreadUnsentMessageChangeInfo(messages: Array(messages) as [ZMConversationMessage])
        case Notification.Name.NewUnreadMessage:
            return NewUnreadMessagesChangeInfo(messages: Array(messages) as [ZMConversationMessage])
        case Notification.Name.NewUnreadKnock:
            return NewUnreadKnockMessagesChangeInfo(messages: Array(messages) as [ZMConversationMessage])
        default:
            return nil
        }
    }
}

