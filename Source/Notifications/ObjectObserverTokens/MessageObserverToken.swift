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

// MARK: Message observing 

private enum MessageKey: String {
    case deliveryState = "deliveryState"
    case mediumData = "mediumData"
    case mediumRemoteIdentifier = "mediumRemoteIdentifier"
    case previewGenericMessage = "previewGenericMessage"
    case mediumGenericMessage = "mediumGenericMessage"
    case linkPreviewState = "linkPreviewState"
    case genericMessage = "genericMessage"
    case reactions = "reactions"
    case isObfuscated = "isObfuscated"
}

extension ZMMessage : ObjectInSnapshot {
    
    public var observableKeys : [String] {
        var keys = [MessageKey.deliveryState.rawValue, MessageKey.isObfuscated.rawValue]
        
        if self is ZMImageMessage {
            keys.append(MessageKey.mediumData.rawValue)
            keys.append(MessageKey.mediumRemoteIdentifier.rawValue)
        }
        if self is ZMAssetClientMessage {
            keys.append(ZMAssetClientMessageTransferStateKey)
            keys.append(MessageKey.previewGenericMessage.rawValue)
            keys.append(MessageKey.mediumGenericMessage.rawValue)
            keys.append(ZMAssetClientMessageDownloadedImageKey)
            keys.append(ZMAssetClientMessageDownloadedFileKey)
            keys.append(ZMAssetClientMessageProgressKey)
        }

        if self is ZMClientMessage {
            keys.append(ZMAssetClientMessageDownloadedImageKey)
            keys.append(MessageKey.linkPreviewState.rawValue)
            keys.append(MessageKey.genericMessage.rawValue)
        }
        
        if !(self is ZMSystemMessage) {
            keys.append(MessageKey.reactions.rawValue)
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
        return changedKeysAndOldValues.keys.contains(MessageKey.deliveryState.rawValue)
    }
    
    public var reactionsChanged : Bool {
        return changedKeysAndOldValues.keys.contains(MessageKey.reactions.rawValue) || reactionChangeInfo != nil
    }

    /// Whether the image data on disk changed
    public var imageChanged : Bool {
        return !Set(arrayLiteral: MessageKey.mediumData.rawValue,
            MessageKey.mediumRemoteIdentifier.rawValue,
            MessageKey.previewGenericMessage.rawValue,
            MessageKey.mediumGenericMessage.rawValue,
            ZMAssetClientMessageDownloadedImageKey
        ).isDisjoint(with: Set(changedKeysAndOldValues.keys))
    }
    
    /// Whether the file on disk changed
    public var fileAvailabilityChanged: Bool {
        return changedKeysAndOldValues.keys.contains(ZMAssetClientMessageDownloadedFileKey)
    }

    public var usersChanged : Bool {
        return userChangeInfo != nil
    }
    
    fileprivate var linkPreviewDataChanged: Bool {
        guard let genericMessage = (message as? ZMClientMessage)?.genericMessage else { return false }
        guard let oldGenericMessage = changedKeysAndOldValues[MessageKey.genericMessage.rawValue] as? ZMGenericMessage else { return false }
        let oldLinks = oldGenericMessage.linkPreviews
        let newLinks = genericMessage.linkPreviews
        
        return oldLinks != newLinks
    }
    
    public var linkPreviewChanged: Bool {
        return changedKeysAndOldValues.keys.contains(MessageKey.linkPreviewState.rawValue) || linkPreviewDataChanged
    }

    public var senderChanged : Bool {
        if self.usersChanged && (self.userChangeInfo?.user as? ZMUser ==  self.message.sender){
            return true
        }
        return false
    }
    
    public var isObfuscatedChanged : Bool {
        return changedKeysAndOldValues.keys.contains(MessageKey.isObfuscated.rawValue)
    }
    
    public var userChangeInfo : UserChangeInfo?
    fileprivate var reactionChangeInfo : ReactionChangeInfo?
    
    public let message : ZMMessage
}


public final class MessageObserverToken: ObjectObserverTokenContainer, ZMUserObserver, ReactionObserver {
    
    typealias InnerTokenType = ObjectObserverToken<MessageChangeInfo,MessageObserverToken>


    fileprivate let observedMessage: ZMMessage
    fileprivate weak var observer : ZMMessageObserver?
    fileprivate var userTokens: [UserCollectionObserverToken] = []
    
    fileprivate var reactionTokens : [Reaction : ReactionObserverToken] = [:]
    
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
            if changeInfo.reactionsChanged {
                if let strongSelf = self {
                    strongSelf.createTokensForReactions(Array<Reaction>(strongSelf.observedMessage.reactions))
                }
            }
            self?.observer?.messageDidChange(changeInfo)
        }
        
        self.createTokensForReactions(Array<Reaction>(self.observedMessage.reactions))
        
        if let sender = object.sender {
            self.userTokens.append(self.createTokenForUser(sender))
        }
        if let systemMessage = object as? ZMSystemMessage {
            for user in systemMessage.users {
                userTokens.append(self.createTokenForUser(user))
            }
        }
    }
    
    fileprivate func createTokensForReactions(_ reactions: [Reaction]) {
        for reaction in reactions {
            if self.reactionTokens[reaction] == nil {
                let reactionToken = ReactionObserverToken(observer: self, observedObject: reaction)
                self.reactionTokens[reaction] = reactionToken
            }
        }
    }
    
    fileprivate func createTokenForUser(_ user: ZMUser) -> UserCollectionObserverToken {
        let token = ZMUser.add(self, forUsers: [user], managedObjectContext: user.managedObjectContext!)
        return token as! UserCollectionObserverToken
    }
    
    public func userDidChange(_ changes: UserChangeInfo){
        if (changes.nameChanged || changes.accentColorValueChanged || changes.imageMediumDataChanged || changes.imageSmallProfileDataChanged) {
            let changeInfo = MessageChangeInfo(object: self.observedMessage)
            changeInfo.userChangeInfo = changes
            self.observer?.messageDidChange(changeInfo)
        }
    }
    
    func reactionDidChange(_ reactionInfo: ReactionChangeInfo) {
        let changeInfo = MessageChangeInfo(object: self.observedMessage)
        changeInfo.reactionChangeInfo = reactionInfo
        self.observer?.messageDidChange(changeInfo)
    }
    
    override public func tearDown() {

        for token in self.userTokens {
            token.tearDown()
        }
        
        for token in self.reactionTokens.values {
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

// MARK: - Reaction observer

private let ReactionUsersKey = "users"

extension Reaction : ObjectInSnapshot {
    
    public var observableKeys : [String] {
        return [ReactionUsersKey]
    }
}


public final class ReactionChangeInfo : ObjectChangeInfo {
    
    var usersChanged : Bool {
        return changedKeysAndOldValues.keys.contains(ReactionUsersKey)
    }
}

@objc protocol ReactionObserver {
    func reactionDidChange(_ reactionInfo: ReactionChangeInfo)
}


final class ReactionObserverToken : ObjectObserverTokenContainer {
    typealias ReactionTokenType = ObjectObserverToken<ReactionChangeInfo, ReactionObserverToken>
    
    fileprivate let observedReaction : Reaction
    fileprivate weak var observer : ReactionObserver?
    
    init (observer: ReactionObserver, observedObject: Reaction) {
        
        self.observer = observer
        self.observedReaction = observedObject
        
        var changeHandler: (ReactionObserverToken, ReactionChangeInfo) -> () = { _ in  }
        
        let innerToken = ReactionTokenType.token(observedObject,
                                                 observableKeys: [ReactionUsersKey],
                                                 managedObjectContextObserver: observedObject.managedObjectContext!.globalManagedObjectContextObserver,
                                                 changeHandler: { changeHandler($0, $1) })
        super.init(object: observedObject, token: innerToken)
        
        innerToken.addContainer(self)
        
        changeHandler = { (_, changeInfo) in
            self.observer?.reactionDidChange(changeInfo)
        }
        
    }
    
    override func tearDown() {
        if let t = self.token as? ReactionTokenType {
            t.removeContainer(self)
            if t.hasNoContainers {
                t.tearDown()
            }
        }
        
        super.tearDown()
    }
}

