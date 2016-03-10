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

public protocol ZMGeneralConversationObserver {
    func conversationDidChange(note: GeneralConversationChangeInfo)
    func tearDown()
}

extension ZMConnection : ObjectInSnapshot {
    
    public var keysToChangeInfoMap : KeyToKeyTransformation { return KeyToKeyTransformation(mapping: [:]) }
    
    public func keyPathsForValuesAffectingValueForKey(key: String) -> Set<String> {
        return ZMConnection.keyPathsForValuesAffectingValueForKey(key) 
    }
}

extension ZMConversation : ObjectInSnapshot {
    
    var defaultMappedKeys: [String] {
        return ["messages", "lastModifiedDate", "isArchived", "conversationListIndicator", "voiceChannelState", "activeFlowParticipants", "callParticipants", "isSilenced", "securityLevel", "otherActiveVideoCallParticipants"]
    }
    
    var customMappedKeys : [String: String] {
        return [ "otherActiveParticipants" : "participantsChanged",
                    "isSelfAnActiveMember" : "participantsChanged",
                             "displayName" : "nameChanged",
                   "attributedDisplayName" : "nameChanged",
                  "relatedConnectionState" : "connectionStateChanged",
                    "estimatedUnreadCount" : "unreadCountChanged",
                        "clearedTimeStamp" : "clearedChanged",
             "hasDownloadedMessageHistory" : "downloadHistoryCompleted"]
    }
    
    public var keysToChangeInfoMap : KeyToKeyTransformation {
        var mapping : [KeyPath : KeyToKeyTransformation.KeyToKeyMappingType] = [:]
        for aKey in defaultMappedKeys {
            mapping[KeyPath.keyPathForString(aKey)] = .Default
        }
        for (key, value) in customMappedKeys {
            mapping[KeyPath.keyPathForString(key)] = .Custom(KeyPath.keyPathForString(value))
        }
        return KeyToKeyTransformation(mapping:mapping)
    }
    
    var internalKeysToChangeInfoMap : KeyToKeyTransformation {
        var mapping : [KeyPath : KeyToKeyTransformation.KeyToKeyMappingType] = [:]
        for aKey in defaultMappedKeys+Array(customMappedKeys.keys) {
            mapping[KeyPath.keyPathForString(aKey)] = KeyToKeyTransformation.KeyToKeyMappingType.None
        }
        return KeyToKeyTransformation(mapping:mapping)
    }
    
    public var keysToPreviousValueInfoMap : KeyToKeyTransformation {
        return KeyToKeyTransformation(mapping: [KeyPath.keyPathForString("voiceChannelState"): .Custom(KeyPath.keyPathForString("previousVoiceChannelState"))])
    }
    
    public func keyPathsForValuesAffectingValueForKey(key: String) -> Set<String> {
        return ZMConversation.keyPathsForValuesAffectingValueForKey(key) 
    }
}

//////////////////////
////
//// GeneralConversationObserver
//// This should be used by all observer token types that observe a ZMConversation
//// It makes sure we only create one token per conversation
////
/////////////////////


public class GeneralConversationChangeInfo : ObjectChangeInfo {
    
    var conversation : ZMConversation { return self.object as! ZMConversation }
    var conversationChangeInfo : ConversationChangeInfo?
    var voiceChannelStateChangeInfo : VoiceChannelStateChangeInfo?
    var callParticipantsChanged = false
    var videoParticipantsChanged = false
    var previousVoiceChannelState : ZMVoiceChannelState = .Invalid {
        didSet {
            if let conv = self.object as? ZMConversation where !conv.isZombieObject {
                createVoiceChannelStateChangeInfoAndSet(previousVoiceChannelState)
            }
        }
    }
    
    private var keysForConversationChangeInfo : Set<String> {
        return Set(arrayLiteral: "messages", "lastModifiedDate", "isArchived", "conversationListIndicator", "voiceChannelState", "isSilenced", "otherActiveParticipants", "isSelfAnActiveMember", "displayName", "attributedDisplayName", "relatedConnectionState", "estimatedUnreadCount", "clearedTimeStamp", "securityLevel", "hasDownloadedMessageHistory")
    }
    
    private var keysForCallParticipantsChangeInfo : Set <String> {
        return Set(arrayLiteral: "activeFlowParticipants", "callParticipants", "otherActiveVideoCallParticipants")
    }
    
    public override var changedKeys : KeySet {
        didSet {
            for key in changedKeys {
                if keysForConversationChangeInfo.contains(key.rawValue)  {
                    if let conv = self.object as? ZMConversation where !conv.isZombieObject {
                        createConversationChangeInfoAndSet(key)
                    }
                }
                if keysForCallParticipantsChangeInfo.contains(key.rawValue) {
                    callParticipantsChanged = true
                    if key.rawValue == "otherActiveVideoCallParticipants" {
                        videoParticipantsChanged = true
                    }
                }
            }
        }
    }
    
    private func createConversationChangeInfoAndSet(key: KeyPath) {
        if conversationChangeInfo == nil {
            conversationChangeInfo = ConversationChangeInfo(object: object)
            conversationChangeInfo!.changedKeys = changedKeys
        }
        if let fieldName = conversation.keysToChangeInfoMap.transformKey(key, defaultTransformation: { $0 + "Changed" } ) {
            conversationChangeInfo!.setValue(1, forKey: fieldName.rawValue)
        }
    }
    
    private func createVoiceChannelStateChangeInfoAndSet(state: ZMVoiceChannelState) {
        voiceChannelStateChangeInfo = VoiceChannelStateChangeInfo(object: object)
        voiceChannelStateChangeInfo!.previousState = state
    }
    
    override public var description : String { return self.debugDescription }
    override public var debugDescription : String {
        return "changedKeys: \(changedKeys), " +
        "previousState \(previousVoiceChannelState),"
    }
}


public final class GeneralConversationObserverToken<T: NSObject where T : ZMGeneralConversationObserver> : ObjectObserverTokenContainer {
    
    typealias InnerTokenType = ObjectObserverToken<GeneralConversationChangeInfo, GeneralConversationObserverToken>
    
    private weak var observer : T?
    
    public init(observer: T, conversation: ZMConversation) {
        self.observer = observer
        
        var wrapper : (NSObject, GeneralConversationChangeInfo) -> () = { _ in return }
        let innerToken = InnerTokenType.token(
            conversation,
            keyToKeyTransformation: conversation.internalKeysToChangeInfoMap,
            keysThatNeedPreviousValue : conversation.keysToPreviousValueInfoMap,
            managedObjectContextObserver : conversation.managedObjectContext!.globalManagedObjectContextObserver,
            observer: { wrapper($0, $1) })
        
        super.init(object:conversation, token:innerToken)
        
        wrapper = {
            [weak self] (_, changeInfo) in
            self?.observer?.conversationDidChange(changeInfo)
        }
        innerToken.addContainer(self)
    }
    
    override public func tearDown() {
        if let t = self.token as? InnerTokenType {
            t.removeContainer(self)
            if t.hasNoContainers {
                t.tearDown()
            }
        }
    }

}


////////////////////
////
//// ConversationObserverToken
//// This can be used for observing only conversation properties
////
////////////////////

@objc public final class ConversationChangeInfo : ObjectChangeInfo {
    
    public var messagesChanged = false
    public var participantsChanged = false
    public var nameChanged = false
    public var lastModifiedDateChanged = false
    public var unreadCountChanged = false
    public var connectionStateChanged = false
    public var isArchivedChanged = false
    public var isSilencedChanged = false
    public var conversationListIndicatorChanged = false
    public var voiceChannelStateChanged = false
    public var clearedChanged = false
    public var securityLevelChanged = false
    public var downloadHistoryCompleted = false
    
    public var conversation : ZMConversation { return self.object as! ZMConversation }
    
    public override var description : String { return self.debugDescription }
    public override var debugDescription : String {
        return "messagesChanged: \(messagesChanged)," +
        "participantsChanged: \(participantsChanged)," +
        "nameChanged: \(nameChanged)," +
        "unreadCountChanged: \(unreadCountChanged)," +
        "lastModifiedDateChanged: \(lastModifiedDateChanged)," +
        "connectionStateChanged: \(connectionStateChanged)," +
        "isArchivedChanged: \(isArchivedChanged)," +
        "isSilencedChanged: \(isSilencedChanged)," +
        "conversationListIndicatorChanged \(conversationListIndicatorChanged)," +
        "voiceChannelStateChanged \(voiceChannelStateChanged)," +
        "clearedChanged \(clearedChanged)," +
        "securityLevelChanged \(securityLevelChanged)," +
        "downloadHistoryCompleted \(downloadHistoryCompleted)"
    }
    
    public required init(object: NSObject) {
        super.init(object: object)
    }
}


/// Conversation degraded
extension ConversationChangeInfo {

    /// Gets the last system message with new clients in the conversation.
    /// If last system message is of the wrong type, it returns nil.
    /// It will search past non-security related system messages, as someone
    /// might have added a participant or renamed the conversation (causing a
    /// system message to be inserted)
    private var recentNewClientsSystemMessageWithExpiredMessages : ZMSystemMessage? {
        if(!self.securityLevelChanged || self.conversation.securityLevel != .SecureWithIgnored) {
            return .None;
        }
        var foundSystemMessage : ZMSystemMessage? = .None
        var foundExpiredMessage = false
        self.conversation.messages.enumerateObjectsWithOptions(NSEnumerationOptions.Reverse) { (msg, _, stop) -> Void in
            if let systemMessage = msg as? ZMSystemMessage {
                if systemMessage.systemMessageType == .NewClient {
                    foundSystemMessage = systemMessage
                }
                if systemMessage.systemMessageType == .NewClient ||
                    systemMessage.systemMessageType == .IgnoredClient ||
                    systemMessage.systemMessageType == .ConversationIsSecure {
                        stop.memory = true
                }
            } else if let sentMessage = msg as? ZMMessage where sentMessage.isExpired {
                foundExpiredMessage = true
            }
        }
        return foundExpiredMessage ? foundSystemMessage : .None
    }
    
    /// True if the conversation was just degraded
    public var didDegradeSecurityLevelBecauseOfMissingClients : Bool {
        return self.recentNewClientsSystemMessageWithExpiredMessages != .None
    }
    
    /// Users that caused the conversation to degrade
    public var usersThatCausedConversationToDegrade : Set<ZMUser> {
        if let message = self.recentNewClientsSystemMessageWithExpiredMessages {
            return message.users
        }
        return Set<ZMUser>()
    }
}


@objc public final class ConversationObserverToken : NSObject, ZMGeneralConversationObserver {
    
    private weak var observer : ZMConversationObserver?
    private var conversationToken : GeneralConversationObserverToken<ConversationObserverToken>?
    
    public init(observer: ZMConversationObserver, conversation: ZMConversation) {
        self.observer = observer
        super.init()
        self.conversationToken = GeneralConversationObserverToken(observer: self, conversation: conversation)
    }
    
    public func conversationDidChange(note: GeneralConversationChangeInfo) {
        if let conversationInfo = note.conversationChangeInfo {
            if let observer = observer {
                observer.conversationDidChange(conversationInfo)
            }
        }
    }
    
    public func tearDown() {
        conversationToken?.tearDown()
    }
}


