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

extension ZMVoiceChannel : ObjectInSnapshot {
    
    public var keysToChangeInfoMap : KeyToKeyTransformation { return KeyToKeyTransformation(mapping: [:])
    }
    
    public func keyPathsForValuesAffectingValueForKey(key: String) -> Set<String> {
        return ZMVoiceChannel.keyPathsForValuesAffectingValueForKey(key) 
    }
    
}



///////////////////
///
/// State
///
///////////////////

///TODO MEC-1236 : to skip intermediate updates we can define valid transitions and check update if it's valid. If it's not we ignore it.

@objc public final class VoiceChannelStateChangeInfo : ObjectChangeInfo {
    
    public required init(object: NSObject) {
        self.previousState = .Invalid
        super.init(object: object)
    }
    
    public var previousState : ZMVoiceChannelState
    public var currentState : ZMVoiceChannelState {
        if let conversation = object as? ZMConversation,
            let state = conversation.voiceChannel?.state {
            return state
        }
        return .Invalid
    }
    public var voiceChannel : ZMVoiceChannel? { return (self.object as? ZMConversation)?.voiceChannel }
    
    public override var description: String {
        return "Call state changed from \(previousState) to \(currentState)"
    }
    
}

extension ZMVoiceChannelState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .Invalid: return "Invalid"
        case .NoActiveUsers: return "NoActiveUsers"
        case .OutgoingCall: return "OutgoingCall"
        case .OutgoingCallInactive: return "OutgoingCallInactive"
        case .IncomingCall: return "IncomingCall"
        case .IncomingCallInactive: return "IncomingCallInactive"
        case .SelfIsJoiningActiveChannel: return "SelfIsJoiningActiveChannel"
        case .SelfConnectedToActiveChannel: return "SelfConnectedToActiveChannel"
        case .DeviceTransferReady: return "DeviceTransferReady"
        }
    }
}

@objc public final class VoiceChannelStateObserverToken : NSObject, ZMGeneralConversationObserver {
    
    private weak var observer : ZMVoiceChannelStateObserver?
    private var conversationToken : GeneralConversationObserverToken<VoiceChannelStateObserverToken>?
    
    public init(observer: ZMVoiceChannelStateObserver, conversation: ZMConversation){
        self.observer = observer
        super.init()

        self.conversationToken = GeneralConversationObserverToken(observer: self, conversation: conversation)
    }
    
    public func conversationDidChange(note: GeneralConversationChangeInfo) {
        if let voiceChannelInfo = note.voiceChannelStateChangeInfo {
            observer?.voiceChannelStateDidChange(voiceChannelInfo)
        }
    }
    
    public func tearDown() {
        conversationToken?.tearDown()
    }
}


public final class GlobalVoiceChannelStateObserverToken : NSObject {
    
    private weak var observer : ZMVoiceChannelStateObserver?
    
    public init(observer: ZMVoiceChannelStateObserver) {
        self.observer = observer
    }
    
    public func notifyObserver(changeInfo: VoiceChannelStateChangeInfo?) {
        self.observer?.voiceChannelStateDidChange(changeInfo)
    }
}


/////////////////////
///
/// CallParticipantState
///
/////////////////////



@objc public final class VoiceChannelParticipantsChangeInfo: SetChangeInfo {
    
    init(setChangeInfo: SetChangeInfo) {
        self.conversation = setChangeInfo.observedObject as! ZMConversation
        super.init(observedObject: conversation, changeSet: setChangeInfo.changeSet)
    }
    
    private let conversation : ZMConversation
    public var voiceChannel : ZMVoiceChannel { return self.conversation.voiceChannel }
    public var otherActiveVideoCallParticipantsChanged : Bool = false
}


@objc public final class VoiceChannelParticipantsObserverToken: NSObject, ZMGeneralConversationObserver, ObjectsDidChangeDelegate  {

    private var state : SetSnapshot
    private var activeFlowParticipantsState : OrderedSet<NSObject>

    private weak var observer : ZMVoiceChannelParticipantsObserver?
    private let conversation : ZMConversation

    private var conversationToken : GeneralConversationObserverToken<VoiceChannelParticipantsObserverToken>?
    private var shouldRecalculate = false
    private var videoParticipantsChanged = false
    
    public init(observer: ZMVoiceChannelParticipantsObserver, voiceChannel: ZMVoiceChannel) {
        self.observer = observer
        self.conversation = voiceChannel.conversation!

        self.state = SetSnapshot(set: OrderedSet(orderedSet: self.conversation.voiceChannel.participants()), moveType: .UICollectionView)
        self.activeFlowParticipantsState = OrderedSet(orderedSet: self.conversation.activeFlowParticipants)
        
        super.init()
        self.conversationToken = GeneralConversationObserverToken(observer: self, conversation:voiceChannel.conversation!)
    }
    
    deinit {
        self.tearDown()
    }
    
    public func conversationDidChange(note: GeneralConversationChangeInfo) {
        if note.callParticipantsChanged { // || note.activeFlowParticipantsChanged {
            if note.videoParticipantsChanged {
                self.videoParticipantsChanged = true
            }
            self.shouldRecalculate = true
        }
    }
    
    public func objectsDidChange(changes: ManagedObjectChanges) {
        if self.shouldRecalculate || self.videoParticipantsChanged {
            self.recalculateSet()
        }
    }
    
    public func recalculateSet() {
        
        self.shouldRecalculate = false
        let participants = OrderedSet(orderedSet: self.conversation.voiceChannel.participants())
        let activeFlowParticipants = OrderedSet(orderedSet: self.conversation.activeFlowParticipants)

        // participants who have an updated flow, but are still in the voiceChannel
        let newConnected = activeFlowParticipants.minus(self.activeFlowParticipantsState)
        let newDisconnected = self.activeFlowParticipantsState.minus(activeFlowParticipants)
        
        // participants who left the voiceChannel / call
        let newLeft = participants.minus(self.state.set)
        let newAdded = self.state.set.minus(participants)
        
        let updated = newConnected.union(newDisconnected).minus(newLeft).minus(newAdded)
        
        // calculate inserts / deletes / moves
        if let newStateUpdate = self.state.updatedState(updated, observedObject: self.conversation, newSet: participants) {
            self.state = newStateUpdate.newSnapshot
            self.activeFlowParticipantsState = activeFlowParticipants
            let changeInfo = VoiceChannelParticipantsChangeInfo(setChangeInfo: newStateUpdate.changeInfo)
            changeInfo.otherActiveVideoCallParticipantsChanged = videoParticipantsChanged
            self.observer?.voiceChannelParticipantsDidChange(changeInfo)
        } else if videoParticipantsChanged {
            let changeInfo = VoiceChannelParticipantsChangeInfo(setChangeInfo: SetChangeInfo(observedObject: conversation))
            changeInfo.otherActiveVideoCallParticipantsChanged = videoParticipantsChanged
            self.observer?.voiceChannelParticipantsDidChange(changeInfo)
        }
        videoParticipantsChanged = false
    }

    
    public func tearDown() {
        self.conversationToken?.tearDown()
    }
    
}
