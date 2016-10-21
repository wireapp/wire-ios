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

public protocol ZMGeneralConversationObserver {
    func conversationDidChange(_ note: GeneralConversationChangeInfo)
    func tearDown()
}

extension ZMConversation : ObjectInSnapshot {
    
    public var observableKeys : [String] {
        var keys = ["messages", "lastModifiedDate", "isArchived", "conversationListIndicator", "voiceChannelState", "activeFlowParticipants", "callParticipants", "isSilenced", "securityLevel", "otherActiveVideoCallParticipants", "displayName", "estimatedUnreadCount", "clearedTimeStamp"]
        if self.conversationType == .group {
            keys.append("otherActiveParticipants")
            keys.append("isSelfAnActiveMember")
            return keys
        }
        keys.append("relatedConnectionState")
        return keys
    }
    
    public func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        return ZMConversation.keyPathsForValuesAffectingValue(forKey: key) 
    }
}




open class GeneralConversationChangeInfo : ObjectChangeInfo {
    
    var conversation : ZMConversation { return self.object as! ZMConversation }
    
    
    internal var internalConversationChangeInfo : ConversationChangeInfo?
    internal var internalVoiceChannelStateChangeInfo : VoiceChannelStateChangeInfo?
    var callParticipantsChanged : Bool {
        return !keysForCallParticipantsChangeInfo.isDisjoint(with: changedKeysAndOldValues.keys)
    }
    var videoParticipantsChanged : Bool {
        return changedKeysAndOldValues.keys.contains("otherActiveVideoCallParticipants")
    }
    
    fileprivate var keysForConversationChangeInfo : Set<String> {
        return Set(arrayLiteral: "messages", "lastModifiedDate", "isArchived", "conversationListIndicator", "voiceChannelState", "isSilenced", "otherActiveParticipants", "isSelfAnActiveMember", "displayName", "relatedConnectionState", "estimatedUnreadCount", "clearedTimeStamp", "securityLevel")
    }
    
    fileprivate var keysForCallParticipantsChangeInfo : Set <String> {
        return Set(arrayLiteral: "activeFlowParticipants", "callParticipants", "otherActiveVideoCallParticipants")
    }
    
    func setAllKeys() {
        // we register conversation observers lazily when we receive a change from a save notification
        // in this case we don't know which keys changed nor their previous value, therefore we set all of them to true
        let keys = keysForConversationChangeInfo.union(keysForCallParticipantsChangeInfo)
        var dict : Dictionary<String, NSObject?> = [:]
        
        for key in keys {
            dict[key] = "" as NSObject?
        }
        
        changedKeysAndOldValues = dict
    }

    var conversationChangeInfo : ConversationChangeInfo? {
        if internalConversationChangeInfo == nil && !keysForConversationChangeInfo.isDisjoint(with: changedKeysAndOldValues.keys) {
            internalConversationChangeInfo = ConversationChangeInfo(object: object)
            internalConversationChangeInfo!.changedKeysAndOldValues = changedKeysAndOldValues
        }
        return internalConversationChangeInfo
    }
    
    var voiceChannelStateChangeInfo : VoiceChannelStateChangeInfo? {
        if internalVoiceChannelStateChangeInfo == nil && changedKeysAndOldValues.keys.contains("voiceChannelState") {
            internalVoiceChannelStateChangeInfo = VoiceChannelStateChangeInfo(object: object)
            internalVoiceChannelStateChangeInfo!.changedKeysAndOldValues = changedKeysAndOldValues
        }
        return internalVoiceChannelStateChangeInfo
    }
    
    override open var description : String { return self.debugDescription }
    override open var debugDescription : String {
        return "changedKeys and old values: \(changedKeysAndOldValues), "
    }
}


//////////////////////
////
//// GeneralConversationObserver
////
/////////////////////

/// This class is an internal class and should not be used to create tokens directly.
/// If you want to register a conversation observer use the GlobalConversationObserver
class GeneralConversationObserverToken<T: NSObject> : ObjectObserverTokenContainer, DisplayNameObserver where T : ZMGeneralConversationObserver  {
    
    typealias InnerTokenType = ObjectObserverToken<GeneralConversationChangeInfo, GeneralConversationObserverToken>
    
    var isTornDown : Bool = false
    fileprivate weak var observer : T?
    var conversation : ZMConversation? {
        return self.object as? ZMConversation
    }    
    
    init(observer: T, conversation: ZMConversation) {
        self.observer = observer

        var changeHandler : (NSObject, GeneralConversationChangeInfo) -> () = { _ in return }
        let innerToken = InnerTokenType.token(
            conversation,
            observableKeys: conversation.observableKeys,
            managedObjectContextObserver : conversation.managedObjectContext!.globalManagedObjectContextObserver,
            changeHandler: { changeHandler($0, $1) })
        
        super.init(object:conversation, token:innerToken)
        
        changeHandler = {
            [weak self] (_, changeInfo) in
            self?.observer?.conversationDidChange(changeInfo)
        }
        innerToken.addContainer(self)
        conversation.managedObjectContext?.globalManagedObjectContextObserver.addDisplayNameObserver(self)
    }
    
     override func tearDown() {
        if isTornDown { return }
        isTornDown = true
        if let t = self.token as? InnerTokenType {
            if !t.hasNoContainers  {
                t.removeContainer(self)
            }
            if t.hasNoContainers {
                t.tearDown()
            }
        }
        conversation?.managedObjectContext?.globalManagedObjectContextObserver.removeDisplayNameObserver(self)
    }
    
    func displayNameMightChange(_ users: Set<NSObject>) {
        guard users.count > 0,
            let conversation = conversation
            , (conversation.userDefinedName == nil || conversation.userDefinedName!.isEmpty || conversation.conversationType != .group) && conversation.activeParticipants.intersectsSet(users)
            else { return }

        (self.token as? InnerTokenType)?.keysHaveChanged(["displayName"])
    }
    
    func connectionDidChange(_ changedConversations: [ZMConversation]) {
        guard let conversation = conversation , conversation.conversationType != .group && changedConversations.index(of: conversation) != nil,
            let token = token as? InnerTokenType
            else { return }
        
        token.keysHaveChanged(["connection"])
    }
}


////////////////////
////
//// ConversationObserverToken
//// This can be used for observing only conversation properties
////
////////////////////

@objc public final class ConversationChangeInfo : ObjectChangeInfo {
    
    public var messagesChanged : Bool {
        return changedKeysAndOldValues.keys.contains("messages")
    }

    public var participantsChanged : Bool {
        return !Set(arrayLiteral: "otherActiveParticipants", "isSelfAnActiveMember").isDisjoint(with: changedKeysAndOldValues.keys)
    }

    public var nameChanged : Bool {
        return changedKeysAndOldValues.keys.contains("displayName")
    }

    public var lastModifiedDateChanged : Bool {
        return changedKeysAndOldValues.keys.contains("lastModifiedDate")
    }

    public var unreadCountChanged : Bool {
        return changedKeysAndOldValues.keys.contains("estimatedUnreadCount")
    }

    public var connectionStateChanged : Bool {
        return changedKeysAndOldValues.keys.contains("relatedConnectionState")
    }

    public var isArchivedChanged : Bool {
        return changedKeysAndOldValues.keys.contains("isArchived")
    }

    public var isSilencedChanged : Bool {
        return changedKeysAndOldValues.keys.contains("isSilenced")
    }

    public var conversationListIndicatorChanged : Bool {
        return changedKeysAndOldValues.keys.contains("conversationListIndicator")
    }

    public var voiceChannelStateChanged : Bool {
        return changedKeysAndOldValues.keys.contains("voiceChannelState")
    }

    public var clearedChanged : Bool {
        return changedKeysAndOldValues.keys.contains("clearedTimeStamp")
    }

    public var securityLevelChanged : Bool {
        return changedKeysAndOldValues.keys.contains("securityLevel")
    }

    
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
        "securityLevelChanged \(securityLevelChanged),"
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
    fileprivate var recentNewClientsSystemMessageWithExpiredMessages : ZMSystemMessage? {
        if(!self.securityLevelChanged || self.conversation.securityLevel != .secureWithIgnored) {
            return .none;
        }
        var foundSystemMessage : ZMSystemMessage? = .none
        var foundExpiredMessage = false
        self.conversation.messages.enumerateObjects(options: NSEnumerationOptions.reverse) { (msg, _, stop) -> Void in
            if let systemMessage = msg as? ZMSystemMessage {
                if systemMessage.systemMessageType == .newClient {
                    foundSystemMessage = systemMessage
                }
                if systemMessage.systemMessageType == .newClient ||
                    systemMessage.systemMessageType == .ignoredClient ||
                    systemMessage.systemMessageType == .conversationIsSecure {
                        stop.pointee = true
                }
            } else if let sentMessage = msg as? ZMMessage , sentMessage.isExpired {
                foundExpiredMessage = true
            }
        }
        return foundExpiredMessage ? foundSystemMessage : .none
    }
    
    /// True if the conversation was just degraded
    public var didDegradeSecurityLevelBecauseOfMissingClients : Bool {
        return self.recentNewClientsSystemMessageWithExpiredMessages != .none
    }
    
    /// Users that caused the conversation to degrade
    public var usersThatCausedConversationToDegrade : Set<ZMUser> {
        if let message = self.recentNewClientsSystemMessageWithExpiredMessages {
            return message.users
        }
        return Set<ZMUser>()
    }
}


@objc public final class ConversationObserverToken: NSObject, ChangeNotifierToken {
   
    typealias Observer = ZMConversationObserver
    typealias ChangeInfo = ConversationChangeInfo
    typealias GlobalObserver = GlobalConversationObserver
    
    fileprivate weak var observer : ZMConversationObserver?
    fileprivate weak var globalObserver: GlobalConversationObserver?
    
    init(observer: Observer, globalObserver: GlobalConversationObserver) {
        self.observer = observer
        self.globalObserver = globalObserver
        super.init()
    }
    
    func notifyObserver(_ change: ConversationChangeInfo) {
        observer?.conversationDidChange(change)
    }
    public func tearDown() {
        globalObserver?.removeConversationObserverForToken(self)
    }
}


