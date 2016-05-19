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


extension ZMMessage : ObjectInSnapshot {
    
    public var observableKeys : [String] {
        var keys = ["deliveryState"]
        
        if self is ZMImageMessage {
            keys.append("mediumData")
            keys.append("mediumRemoteIdentifier")
        }
        if self is ZMAssetClientMessage {
            keys.append(ZMAssetClientMessageTransferStateKey)
            keys.append("previewGenericMessage")
            keys.append("mediumGenericMessage")
            keys.append(ZMAssetClientMessageDownloadedImageKey)
            keys.append(ZMAssetClientMessageDownloadedFileKey)
            keys.append(ZMAssetClientMessageProgressKey)
        }
        return keys
    }
}

@objc final public class MessageChangeInfo : ObjectChangeInfo {
    
    public required init(object: NSObject) {
        self.message = object as! ZMMessage
        super.init(object: object)
    }
    public var deliveryStateChanged : Bool {
        return changedKeysAndOldValues.keys.contains("deliveryState")
    }

    /// Whether the image data on disk changed
    public var imageChanged : Bool {
        return !Set(arrayLiteral: "mediumData",
            "mediumRemoteIdentifier",
            "previewGenericMessage",
            "mediumGenericMessage",
            ZMAssetClientMessageDownloadedImageKey
        ).isDisjointWith(changedKeysAndOldValues.keys)
    }
    
    /// Whether the file on disk changed
    public var fileAvailabilityChanged: Bool {
        return changedKeysAndOldValues.keys.contains(ZMAssetClientMessageDownloadedFileKey)
    }

    public var usersChanged : Bool {
        return userChangeInfo != nil
    }

    public var senderChanged : Bool {
        if self.usersChanged && (self.userChangeInfo?.user as? ZMUser ==  self.message.sender){
            return true
        }
        return false
    }
    
    public var userChangeInfo : UserChangeInfo?
    
    public let message : ZMMessage
}


public final class MessageObserverToken: ObjectObserverTokenContainer, ZMUserObserver {
    
    typealias InnerTokenType = ObjectObserverToken<MessageChangeInfo,MessageObserverToken>

    private let observedMessage: ZMMessage
    private weak var observer : ZMMessageObserver?
    private var userTokens: [UserCollectionObserverToken] = []
    
    public init(observer: ZMMessageObserver, object: ZMMessage) {
        self.observedMessage = object
        self.observer = observer
        
        var changeHandler : (MessageObserverToken, MessageChangeInfo) -> () = { _ in return }
        let innerToken = InnerTokenType.token(
            object,
            observableKeys: object.observableKeys,
            managedObjectContextObserver : object.managedObjectContext!.globalManagedObjectContextObserver,
            changeHandler: { changeHandler($0, $1) }
        )
        
        super.init(object:object, token: innerToken)
        
        innerToken.addContainer(self)
        
        changeHandler = {
            [weak self] (_, changeInfo) in
            self?.observer?.messageDidChange(changeInfo)
        }
        
        if let sender = object.sender {
            self.userTokens.append(self.createTokenForUser(sender))
        }
        if let systemMessage = object as? ZMSystemMessage {
            for user in systemMessage.users {
                userTokens.append(self.createTokenForUser(user))
            }
        }
    }
    
    private func createTokenForUser(user: ZMUser) -> UserCollectionObserverToken {
        let token = ZMUser.addUserObserver(self, forUsers: [user], managedObjectContext: user.managedObjectContext!)
        return token as! UserCollectionObserverToken
    }
    
    public func userDidChange(changes: UserChangeInfo){
        if (changes.nameChanged || changes.accentColorValueChanged || changes.imageMediumDataChanged || changes.imageSmallProfileDataChanged) {
            let changeInfo = MessageChangeInfo(object: self.observedMessage)
            changeInfo.userChangeInfo = changes
            self.observer?.messageDidChange(changeInfo)
        }
    }
    
    override public func tearDown() {

        for token in self.userTokens {
            token.tearDown()
        }
        self.userTokens = []
        
        if let t = self.token as? InnerTokenType {
            t.removeContainer(self)
            if t.hasNoContainers {
                t.tearDown()
            }
        }
        super.tearDown()
    }
    
    deinit {
        self.tearDown()
    }
    
}

