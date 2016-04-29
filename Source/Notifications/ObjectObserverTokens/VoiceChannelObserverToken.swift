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
    
    public var observableKeys : [String] {return []}

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
        super.init(object: object)
    }
    
    public var previousState : ZMVoiceChannelState {
        guard let rawValue = (changedKeysAndOldValues["voiceChannelState"] as? NSInteger),
              let previousState = ZMVoiceChannelState(rawValue: UInt8(rawValue))
        else { return .Invalid }
        
        return previousState
    }
    
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

@objc public final class VoiceChannelStateObserverToken : NSObject, ChangeNotifierToken {
    
    typealias Observer = ZMVoiceChannelStateObserver
    typealias ChangeInfo = VoiceChannelStateChangeInfo
    typealias GlobalObserver = GlobalConversationObserver
    
    private weak var observer : ZMVoiceChannelStateObserver?
    weak var globalObserver : GlobalConversationObserver?

    init(observer: ZMVoiceChannelStateObserver, globalObserver: GlobalConversationObserver){
        self.observer = observer
        self.globalObserver = globalObserver
    }
    
    func notifyObserver(note: VoiceChannelStateChangeInfo) {
        observer?.voiceChannelStateDidChange(note)
    }
    
    public func tearDown() {
        globalObserver?.removeVoiceChannelStateObserverForToken(self)
    }
}


public final class GlobalVoiceChannelStateObserverToken : NSObject {
    
    private weak var observer : ZMVoiceChannelStateObserver?
    weak var globalObserver : GlobalConversationObserver?

    public init(observer: ZMVoiceChannelStateObserver) {
        self.observer = observer
    }
    
    public func notifyObserver(changeInfo: VoiceChannelStateChangeInfo?) {
        self.observer?.voiceChannelStateDidChange(changeInfo)
    }
    
    public func tearDown() {
        globalObserver?.removeGlobalVoiceChannelStateObserver(self)
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
    
    let conversation : ZMConversation
    public var voiceChannel : ZMVoiceChannel { return self.conversation.voiceChannel }
    public var otherActiveVideoCallParticipantsChanged : Bool = false
}


@objc public final class VoiceChannelParticipantsObserverToken: NSObject, ChangeNotifierToken  {
    typealias Observer = ZMVoiceChannelParticipantsObserver
    typealias ChangeInfo = VoiceChannelParticipantsChangeInfo
    typealias GlobalObserver = GlobalConversationObserver

    private weak var observer : ZMVoiceChannelParticipantsObserver?
    private weak var globalObserver : GlobalConversationObserver?
    private var videoParticipantsChanged = false
    
    init(observer: ZMVoiceChannelParticipantsObserver, globalObserver: GlobalConversationObserver) {
        self.observer = observer
        self.globalObserver = globalObserver
    }
    
    func notifyObserver(note: ChangeInfo) {
        observer?.voiceChannelParticipantsDidChange(note)
    }
    
    func tearDown() {
        globalObserver?.removeVoiceChannelParticipantsObserverForToken(self)
    }
    
}

class InternalVoiceChannelParticipantsObserverToken: NSObject, ObjectsDidChangeDelegate  {

    private var state : SetSnapshot
    private var activeFlowParticipantsState : OrderedSet<NSObject>
    
    private weak var globalObserver : GlobalConversationObserver?
    private var conversation : ZMConversation
    
    private var shouldRecalculate = false
    var isTornDown : Bool = false
    private var videoParticipantsChanged = false

    init(observer: GlobalConversationObserver, conversation: ZMConversation) {
        self.globalObserver = observer
        self.conversation = conversation
        
        self.state = SetSnapshot(set: OrderedSet(orderedSet: self.conversation.voiceChannel.participants()), moveType: .UICollectionView)
        self.activeFlowParticipantsState = OrderedSet(orderedSet: self.conversation.activeFlowParticipants)
        
        super.init()
    }
    
    deinit {
        self.tearDown()
    }
    
    func conversationDidChange(note: GeneralConversationChangeInfo) {
        if note.callParticipantsChanged { // || note.activeFlowParticipantsChanged {
            self.videoParticipantsChanged = note.videoParticipantsChanged
            self.shouldRecalculate = true
        }
    }
    
    func objectsDidChange(changes: ManagedObjectChanges) {
        if self.shouldRecalculate {
            self.recalculateSet()
        }
    }
    
    func recalculateSet() {
        
        self.shouldRecalculate = false
        let participants = OrderedSet(orderedSet: self.conversation.voiceChannel.participants())
        let activeFlowParticipants = OrderedSet(orderedSet: self.conversation.activeFlowParticipants)
        
        // participants who have an updated flow, but are still in the voiceChannel
        let newConnected = activeFlowParticipants.minus(self.activeFlowParticipantsState)
        let newDisconnected = self.activeFlowParticipantsState.minus(activeFlowParticipants)
        
        // participants who left the voiceChannel / call
        let newAdded = participants.minus(self.state.set) 
        let newLeft = self.state.set.minus(participants)
        
        let updated = newConnected.union(newDisconnected).minus(newLeft).minus(newAdded)
        
        // calculate inserts / deletes / moves
        if let newStateUpdate = self.state.updatedState(updated, observedObject: self.conversation, newSet: participants) {
            self.state = newStateUpdate.newSnapshot
            self.activeFlowParticipantsState = activeFlowParticipants
            
            let changeInfo = VoiceChannelParticipantsChangeInfo(setChangeInfo: newStateUpdate.changeInfo)
            changeInfo.otherActiveVideoCallParticipantsChanged = videoParticipantsChanged
            globalObserver?.notifyVoiceChannelParticipantsObserver(changeInfo)
        } else if videoParticipantsChanged {
            let changeInfo = VoiceChannelParticipantsChangeInfo(setChangeInfo: SetChangeInfo(observedObject: conversation))
            changeInfo.otherActiveVideoCallParticipantsChanged = videoParticipantsChanged
            globalObserver?.notifyVoiceChannelParticipantsObserver(changeInfo)
        }
        videoParticipantsChanged = false
    }
    
    
    func tearDown() {
        state = SetSnapshot(set: OrderedSet(), moveType: ZMSetChangeMoveType.None)
        activeFlowParticipantsState = OrderedSet()
        isTornDown = true
    }
    
}
