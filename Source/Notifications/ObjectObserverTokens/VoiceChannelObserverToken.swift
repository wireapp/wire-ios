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

extension ZMVoiceChannel : ObjectInSnapshot {
    
    public var observableKeys : [String] {return []}

    public func keyPathsForValuesAffectingValueForKey(_ key: String) -> Set<String> {
        return ZMVoiceChannel.keyPathsForValuesAffectingValue(forKey: key) 
    }
}

public extension NSOrderedSet {

    public func subtracting(orderedSet: NSOrderedSet) -> NSOrderedSet {
        let mutableSelf = mutableCopy() as! NSMutableOrderedSet
        mutableSelf.minus(orderedSet)
        return NSOrderedSet(orderedSet: mutableSelf)
    }
    
    public func adding(orderedSet: NSOrderedSet) -> NSOrderedSet {
        let mutableSelf = mutableCopy() as! NSMutableOrderedSet
        mutableSelf.union(orderedSet)
        return NSOrderedSet(orderedSet: mutableSelf)
    }
}


///////////////////
///
/// State
///
///////////////////

@objc public final class VoiceChannelStateChangeInfo : ObjectChangeInfo {
    
    public required init(object: NSObject) {
        super.init(object: object)
    }
    
    public var previousState : ZMVoiceChannelState {
        guard let rawValue = (changedKeysAndOldValues["voiceChannelState"] as? NSInteger),
              let previousState = ZMVoiceChannelState(rawValue: UInt8(rawValue))
        else { return .invalid }
        
        return previousState
    }
    
    public var currentState : ZMVoiceChannelState {
        if let conversation = object as? ZMConversation,
            let state = conversation.voiceChannel?.state {
            return state
        }
        return .invalid
    }
    public var voiceChannel : ZMVoiceChannel? { return (object as? ZMConversation)?.voiceChannel }
    
    public override var description: String {
        return "Call state changed from \(previousState) to \(currentState)"
    }
    
}

extension ZMVoiceChannelState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .invalid: return "Invalid"
        case .noActiveUsers: return "NoActiveUsers"
        case .outgoingCall: return "OutgoingCall"
        case .outgoingCallInactive: return "OutgoingCallInactive"
        case .incomingCall: return "IncomingCall"
        case .incomingCallInactive: return "IncomingCallInactive"
        case .selfIsJoiningActiveChannel: return "SelfIsJoiningActiveChannel"
        case .selfConnectedToActiveChannel: return "SelfConnectedToActiveChannel"
        case .deviceTransferReady: return "DeviceTransferReady"
        }
    }
}

@objc public final class VoiceChannelStateObserverToken : NSObject, ChangeNotifierToken {
    
    typealias Observer = ZMVoiceChannelStateObserver
    typealias ChangeInfo = VoiceChannelStateChangeInfo
    typealias GlobalObserver = GlobalConversationObserver
    
    fileprivate weak var observer : ZMVoiceChannelStateObserver?
    weak var globalObserver : GlobalConversationObserver?

    init(observer: ZMVoiceChannelStateObserver, globalObserver: GlobalConversationObserver){
        self.observer = observer
        self.globalObserver = globalObserver
    }
    
    func notifyObserver(_ note: VoiceChannelStateChangeInfo) {
        observer?.voiceChannelStateDidChange(note)
    }
    
    public func tearDown() {
        globalObserver?.removeVoiceChannelStateObserverForToken(self)
    }
}


public final class GlobalVoiceChannelStateObserverToken : NSObject {
    
    fileprivate weak var observer : ZMVoiceChannelStateObserver?
    weak var globalObserver : GlobalConversationObserver?

    public init(observer: ZMVoiceChannelStateObserver) {
        self.observer = observer
    }
    
    public func notifyObserver(_ changeInfo: VoiceChannelStateChangeInfo?) {
        if let changeInfo = changeInfo {
            observer?.voiceChannelStateDidChange(changeInfo)
        }
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
        conversation = setChangeInfo.observedObject as! ZMConversation
        super.init(observedObject: conversation, changeSet: setChangeInfo.changeSet)
    }
    
    let conversation : ZMConversation
    public var voiceChannel : ZMVoiceChannel { return conversation.voiceChannel }
    public var otherActiveVideoCallParticipantsChanged : Bool = false
}


@objc public final class VoiceChannelParticipantsObserverToken: NSObject, ChangeNotifierToken  {
    typealias Observer = ZMVoiceChannelParticipantsObserver
    typealias ChangeInfo = VoiceChannelParticipantsChangeInfo
    typealias GlobalObserver = GlobalConversationObserver

    fileprivate weak var observer : ZMVoiceChannelParticipantsObserver?
    fileprivate weak var globalObserver : GlobalConversationObserver?
    fileprivate var videoParticipantsChanged = false
    
    init(observer: ZMVoiceChannelParticipantsObserver, globalObserver: GlobalConversationObserver) {
        self.observer = observer
        self.globalObserver = globalObserver
    }
    
    func notifyObserver(_ note: ChangeInfo) {
        observer?.voiceChannelParticipantsDidChange(note)
    }
    
    func tearDown() {
        globalObserver?.removeVoiceChannelParticipantsObserverForToken(self)
    }
    
}

class InternalVoiceChannelParticipantsObserverToken: NSObject, ObjectsDidChangeDelegate  {

    fileprivate var state : SetSnapshot
    fileprivate var activeFlowParticipantsState : NSOrderedSet
    
    fileprivate weak var globalObserver : GlobalConversationObserver?
    fileprivate var conversation : ZMConversation
    
    fileprivate var shouldRecalculate = false
    var isTornDown : Bool = false
    fileprivate var videoParticipantsChanged = false

    init(observer: GlobalConversationObserver, conversation: ZMConversation) {
        self.globalObserver = observer
        self.conversation = conversation
        
        state = SetSnapshot(set: conversation.voiceChannel.participants(), moveType: .uiCollectionView)
        activeFlowParticipantsState = conversation.activeFlowParticipants.copy() as! NSOrderedSet
        
        super.init()
    }
    
    deinit {
        tearDown()
    }
    
    func conversationDidChange(_ note: GeneralConversationChangeInfo) {
        if note.callParticipantsChanged { // || note.activeFlowParticipantsChanged {
            videoParticipantsChanged = note.videoParticipantsChanged
            shouldRecalculate = true
        }
    }
    
    func objectsDidChange(_ changes: ManagedObjectChanges, accumulated: Bool) {
        if shouldRecalculate {
            recalculateSet()
        }
    }
    
    func recalculateSet() {
        
        shouldRecalculate = false
        let newParticipants = conversation.voiceChannel.participants() ?? NSOrderedSet()
        let newFlowParticipants = conversation.activeFlowParticipants

        // participants who have an updated flow, but are still in the voiceChannel
        let newConnected = newFlowParticipants.subtracting(orderedSet: activeFlowParticipantsState)
        let newDisconnected = activeFlowParticipantsState.subtracting(orderedSet: newFlowParticipants)

        // participants who left the voiceChannel / call
        let addedUsers = newParticipants.subtracting(orderedSet: state.set)
        let removedUsers = state.set.subtracting(orderedSet: newParticipants)

        let updated = newConnected.adding(orderedSet: newDisconnected)
                                  .subtracting(orderedSet: removedUsers)
                                  .subtracting(orderedSet: addedUsers)

        // calculate inserts / deletes / moves
        if let newStateUpdate = state.updatedState(updated, observedObject: conversation, newSet: newParticipants) {
            state = newStateUpdate.newSnapshot
            activeFlowParticipantsState = (conversation.activeFlowParticipants.copy() as? NSOrderedSet) ?? NSOrderedSet()
            
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
        state = SetSnapshot(set: NSOrderedSet(), moveType: ZMSetChangeMoveType.none)
        activeFlowParticipantsState = NSOrderedSet()
        isTornDown = true
    }
    
}
