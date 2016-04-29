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
import CoreData
import ZMCSystem;


private let zmLog = ZMSLog(tag: "CallState")

private let UserInfoCallStateKey = "ZMCallState"

@objc
public enum ZMCallStateReasonToLeave : UInt {
    /// Client has not requested to leave the voice channel
    case None
    /// Self user has requested to leave the voice channel
    case User
    /// AVS reported an error which forced us to leave the voice channel
    case AVSError
}

@objc public class ZMCallStateReasonToLeaveDescriber: NSObject {
    public static func reasonToLeaveToString(reason: ZMCallStateReasonToLeave) -> String {
        switch reason {
        case .None:
            return "none (not requested)"
        case .User:
            return "self user"
        case .AVSError:
            return "AVS error"
        }
    }
}

extension NSManagedObjectContext {
    
    public var zm_callState: ZMCallState {
        let oldState = self.userInfo[UserInfoCallStateKey] as? ZMCallState
        return oldState ?? { () -> ZMCallState in
            let state = ZMCallState(contextType: self.zm_isUserInterfaceContext ? .Main : .Sync)
            zmLog.debug("setting state in context \(self) isUIContext: \(self.zm_isUserInterfaceContext) - \(state.contextType.description)")
            self.userInfo[UserInfoCallStateKey] = state
            return state
        }()
    }
    
    /// Checks hasChanges and callStateHasChanges.
    ///
    /// The call state changes do not dirty the context's objects, hence need to be tracked / checked seperately.
    public var zm_hasChanges: Bool {
        return hasChanges || callStateHasChanges
    }

    public var callStateHasChanges: Bool {
        return zm_callState.hasChanges
    }
    
    public func mergeCallStateChanges(callStateChanges: ZMCallState?) -> Set<ZMConversation> {
        if let copiedState = callStateChanges {
            let idsForChangedConversation = zm_callState.mergeChangesFromState(copiedState)
            let conversations = idsForChangedConversation.map{self.objectWithID($0) as! ZMConversation}
            conversations.forEach{$0.updateLocallyModifiedCallStateKeys()}
            return Set(conversations)
        }
        return Set()
    }
    
    public func firstOtherConversationWithActiveCallOnCurrentDevice(conversation: ZMConversation) -> ZMConversation? {
    	return zm_callState.firstOtherConversationIDThatHasActiveCallOnCurrentDevice(managedObjectID: conversation.objectID).flatMap {
    		self.objectWithID($0) as? ZMConversation
    	}
    }

    public func zm_tearDownCallState() {
        if (self.userInfo[UserInfoCallStateKey] as? ZMCallState) != nil {
            self.userInfo.removeObjectForKey(UserInfoCallStateKey);
        }
    }
}

extension ZMConversation {
    
    private var callState: ZMConversationCallState {
        return managedObjectContext!.zm_callState.stateForConversation(self)
    }
    
    public var callDeviceIsActive: Bool {
        get {
            return callState.isCallDeviceActive
        }
        set {
            callState.isCallDeviceActive = newValue
        }
    }

    public var isFlowActive: Bool {
        get {
            return callState.isFlowActive
        }
        set {
            if callState.isFlowActive != newValue {
                callState.isFlowActive = newValue
            }
        }
    }
    
    public var isIgnoringCall: Bool {
        get {
            return callState.isIgnoringCall
        }
        set {
            if callState.isIgnoringCall != newValue {
                callState.isIgnoringCall = newValue
            }
        }
    }
    
    public var callTimedOut: Bool {
        get {
            return callState.timedOut
        }
        set {
            if callState.timedOut != newValue {
                callState.timedOut = newValue
            }
        }
    }
    
    public var isOutgoingCall: Bool {
        get {
            return callState.isOutgoingCall
        }
        set {
            if callState.isOutgoingCall != newValue {
                callState.isOutgoingCall = newValue
            }
        }
    }
    
    public var reasonToLeave: ZMCallStateReasonToLeave {
        get {
            return callState.reasonToLeave
        }
        set {
            if (callState.reasonToLeave != newValue) {
                callState.reasonToLeave = newValue
            }
        }
    }
    
    public var activeFlowParticipants : NSOrderedSet {
        get {
            let participants = callState.activeFlowParticipants.mapWithBlock{self.managedObjectContext?.objectWithID($0 as! NSManagedObjectID)}
            return participants ?? NSOrderedSet()
        }
        set {
            let objectIDs = newValue.mapWithBlock{($0 as!ZMUser).objectID}
            callState.activeFlowParticipants = objectIDs
        }
    }
    
    public var hasLocalModificationsForCallDeviceIsActive : Bool {
        return callState.hasLocalModificationsForCallDeviceActive
    }
    
    public var firstOtherConversationWithActiveCallOnCurrentDevice : ZMConversation? {
        return managedObjectContext!.firstOtherConversationWithActiveCallOnCurrentDevice(self)
    }

    public func resetHasLocalModificationsForCallDeviceIsActive() {
        callState.resetHasLocalModificationsForCallDeviceActive()
    }
    
    public var hasLocalModificationsForIsVideoCall: Bool {
        return callState.hasLocalModificationsForIsVideoCall
    }
    
    public var hasLocalModificationsForIsIgnoringCall: Bool {
        return callState.hasLocalModificationsForIgnoringCall
    }
    
    public func resetHasLocalModificationsForIsIgnoringCall() {
        callState.resetHasLocalModificationsForIsIgnoringCall()
    }
    
    public func updateLocallyModifiedCallStateKeys(){
        var newKeys = keysThatHaveLocalModifications
        if (callState.hasLocalModificationsForIsSendingVideo) {
            newKeys.insert(ZMConversationCallDeviceIsActiveKey)
        }
        if (callState.hasLocalModificationsForCallDeviceActive) {
            newKeys.insert(ZMConversationCallDeviceIsActiveKey)
        }
        if (callState.hasLocalModificationsForIgnoringCall) {
            newKeys.insert(ZMConversationIsIgnoringCallKey)
        }
        setLocallyModifiedKeys(newKeys)
    }
}

/// MARK: VideoCalling
extension ZMConversation {
    
    public var isVideoCall: Bool {
        get {
            return callState.isVideoCall
        }
        set {
            if callState.isVideoCall != newValue {
                callState.isVideoCall = newValue
            }
        }
    }
    
    public var isSendingVideo : Bool {
        get {
            return callState.isSendingVideo
        }
        set {
            if callState.isSendingVideo != newValue {
                callState.isSendingVideo = newValue
            }
        }
    }
    
    public var hasLocalModificationsForIsSendingVideo: Bool {
        return callState.hasLocalModificationsForIsSendingVideo
    }
    
    public func resetHasLocalModificationsForIsSendingVideo() {
        callState.resetHasLocalModificationsForIsSendingVideo()
    }
    
    public func syncLocalModificationsOfIsSendingVideo(){
        callState.syncLocalModificationsOfIsSendingVideo()
        setLocallyModifiedKeys(Set(arrayLiteral: ZMConversationIsSendingVideoKey))
    }
    
    public func addActiveVideoCallParticipant(user: ZMUser) {
        let participants = callState.activeVideoCallParticipants.mutableCopy()
        participants.addObject(user.objectID)
        callState.activeVideoCallParticipants = participants.copy() as! NSOrderedSet
    }
    
    public func removeActiveVideoCallParticipant(user: ZMUser) {
        let participants = callState.activeVideoCallParticipants.mutableCopy()
        participants.removeObject(user.objectID)
        callState.activeVideoCallParticipants = participants.copy() as! NSOrderedSet
    }

    public var otherActiveVideoCallParticipants: NSOrderedSet {
        get {
            if callState.isFlowActive {
                let participants = callState.activeVideoCallParticipants.mapWithBlock{self.managedObjectContext?.objectWithID($0 as! NSManagedObjectID)}
                return participants ?? NSOrderedSet()
            }
            return NSOrderedSet()
        }
        set {
            let objectIDs = newValue.mapWithBlock{($0 as!ZMUser).objectID}
            callState.activeVideoCallParticipants = objectIDs
        }
    }
}


@objc
public class ZMCallState : NSObject, SequenceType {
    
    public enum Context {
        case Main
        case Sync
        
        var description : String {
            switch self {
            case Main:
                return "Main"
            case Sync:
                return "Sync"
            }
        }
    }
    
    private let contextType : Context
    
    public init(contextType type: Context) {
        contextType = type
    }
    
    private var conversationStates: [NSManagedObjectID:ZMConversationCallState] = [:]
    public var hasChanges: Bool {
        for (_, conversationState) in self {
            if conversationState.hasChanges {
                return true
            }
        }
        return false
    }
    
    private var allObjectIDs : Set<NSManagedObjectID> {
        return Set(conversationStates.keys)
    }
    
    public func allContainedConversationsInContext(moc: NSManagedObjectContext) -> Set<ZMConversation> {
        var r = Set<ZMConversation>()
        for oid in allObjectIDs {
            r.insert(moc.objectWithID(oid) as! ZMConversation)
        }
        return r
    }
    
    public func stateForConversation(conversation: NSManagedObject) -> ZMConversationCallState {
        if (conversation.objectID.temporaryID) {
            do {
                try conversation.managedObjectContext!.obtainPermanentIDsForObjects([conversation])
            } catch let err {
                fatal("Could not obtain permanent object ID from conversation - error: \(err)")
            }
        }
        return stateForConversationID(conversation.objectID)
    }
    
    func stateForConversationID(conversationID: NSManagedObjectID) -> ZMConversationCallState {
        return conversationStates[conversationID] ?? {
            zmLog.debug("inserting new state for conversationID \(conversationID) into \(SwiftDebugging.address(self)) with contextType \(self.contextType.description)")
            let newState = ZMConversationCallState(contextType: self.contextType)
            self.conversationStates[conversationID] = newState
            return newState
            }()
    }
    
    public typealias Generator = DictionaryGenerator<NSManagedObjectID, ZMConversationCallState>
    public func generate() -> Generator {
        return conversationStates.generate()
    }
    public var isEmpty: Bool {
    	return conversationStates.isEmpty
    }
    
    public func firstOtherConversationIDThatHasActiveCallOnCurrentDevice(managedObjectID moid: NSManagedObjectID) -> NSManagedObjectID? {
        if (moid.temporaryID) {
            zmLog.error("The object ID must not be temporary.")
            return nil
        }
        for (otherMOID, conversationState) in self {
            if !conversationState.isIgnoringCall && conversationState.isCallDeviceActive && moid != otherMOID {
                return otherMOID
            }
        }
        return nil
    }
    
    public override var description: String {
        return "CallState \(SwiftDebugging.address(self)) for contextType: \(contextType.description) \n" +
        " --> hasChanges : \(hasChanges)\n" +
        " --> states : \(conversationStates) \n"
    }
    
    public override var debugDescription : String {
        return description
    }
}

/// This is the call state for a specific conversation.
///
/// Fields tracked are
///  * isCallDeviceActive
///  * isUserJoined
///  * isFlowActive
///  * isIgnoringCall
/// additionally
///  * hasChanges
///  * hasLocalModificationsForCallDeviceActive
public class ZMConversationCallState : NSObject {
    
    private let contextType : ZMCallState.Context

    public init(contextType type: ZMCallState.Context) {
        contextType = type
    }
    
    public var isCallDeviceActive: Bool = false {
        didSet {
            hasChanges = true
            if contextType == .Main {
                hasLocalModificationsForCallDeviceActive = true
            }
        }
    }
    
    public var isIgnoringCall: Bool = false {
        didSet {
            hasChanges = true
            if self.contextType == .Main {
                hasLocalModificationsForIgnoringCall = true
            }
        }
    }
    
    public var isFlowActive : Bool = false {
        didSet {
            hasChanges = true
        }
    }
    

    public var activeFlowParticipants : NSOrderedSet = NSOrderedSet() {
        didSet {
            hasChanges = true
            hasLocalModificationsForActiveParticipants = true
        }
    }
    
    public var activeVideoCallParticipants : NSOrderedSet = NSOrderedSet() {
        didSet {
            hasChanges = true
            hasLocalModificationsForActiveVideoCallParticipants = true
        }
    }
    
    public var isOutgoingCall : Bool = false {
        didSet {
            hasChanges = true
            hasLocalModificationsForIsOutgoingCall = true
        }
    }
    
    public var timedOut : Bool = false {
        didSet {
            hasChanges = true
            hasLocalModificationsForTimedOut = true
        }
    }
    
    public var isVideoCall: Bool = false {
        didSet {
            hasChanges = true
            if contextType == .Main {
                hasLocalModificationsForIsVideoCall = true
            }
        }
    }
    
    public var isSendingVideo: Bool = false {
        didSet {
            hasChanges = true
            if contextType == .Main {
                hasLocalModificationsForIsSendingVideo = true
            }
        }
    }
    
    public var reasonToLeave: ZMCallStateReasonToLeave = ZMCallStateReasonToLeave.None {
        didSet {
            guard oldValue != reasonToLeave else { return }
            hasChanges = true
            hasLocalModificationsForReasonToLeave = true
        }
    }

    public func syncLocalModificationsOfIsSendingVideo() {
        needsToSyncIsSendingVideo = true
        hasLocalModificationsForIsSendingVideo = true
        hasChanges = true
    }
    
    
    private (set) public var hasChanges: Bool = false
    private (set) public var hasLocalModificationsForCallDeviceActive: Bool = false
    private (set) public var hasLocalModificationsForIgnoringCall: Bool = false
    private (set) public var hasLocalModificationsForActiveParticipants: Bool = false
    private (set) public var hasLocalModificationsForIsOutgoingCall: Bool = false
    private (set) public var hasLocalModificationsForTimedOut: Bool = false
    
    private (set) public var hasLocalModificationsForActiveVideoCallParticipants: Bool = false
    private (set) public var hasLocalModificationsForIsVideoCall: Bool = false
    private (set) public var hasLocalModificationsForIsSendingVideo: Bool = false
    private (set) public var hasLocalModificationsForReasonToLeave: Bool = false

    private var needsToSyncIsSendingVideo : Bool = false
    
    func resetHasLocalModificationsForCallDeviceActive() {
        if contextType != .Sync {
            zmLog.warn("Resetting hasLocalModificationsForCallDeviceActive on a context that is not the sync context")
        }
        hasLocalModificationsForCallDeviceActive = false
    }
    
    func resetHasLocalModificationsForIsSendingVideo() {
        if contextType != .Sync {
            zmLog.warn("Resetting hasLocalModificationsForIsSendingVideo on a context that is not the sync context")
        }
        hasLocalModificationsForIsSendingVideo = false
        needsToSyncIsSendingVideo = false
    }
    
    func resetHasLocalModificationsForIsIgnoringCall() {
        if contextType != .Sync {
            zmLog.warn("Resetting hasLocalModificationsForIgnoringCall on a context that is not the sync context")
        }
        hasLocalModificationsForIgnoringCall = false
    }

    
    public func createCopy() -> ZMConversationCallState {
        let newState = ZMConversationCallState(contextType: contextType)
        newState.isCallDeviceActive = isCallDeviceActive
        newState.isFlowActive = isFlowActive
        newState.isIgnoringCall = isIgnoringCall
        newState.activeFlowParticipants = activeFlowParticipants
        newState.isOutgoingCall = isOutgoingCall
        newState.timedOut = timedOut
        newState.isVideoCall = isVideoCall
        newState.isSendingVideo = isSendingVideo
        newState.activeVideoCallParticipants = activeVideoCallParticipants
        newState.reasonToLeave = reasonToLeave
        
        newState.hasLocalModificationsForCallDeviceActive = hasLocalModificationsForCallDeviceActive
        newState.hasLocalModificationsForIgnoringCall = hasLocalModificationsForIgnoringCall
        newState.hasLocalModificationsForActiveParticipants = hasLocalModificationsForActiveParticipants
        newState.hasLocalModificationsForIsOutgoingCall = hasLocalModificationsForIsOutgoingCall
        newState.hasLocalModificationsForTimedOut = hasLocalModificationsForTimedOut
        newState.hasLocalModificationsForIsVideoCall = hasLocalModificationsForIsVideoCall
        newState.hasLocalModificationsForIsSendingVideo = hasLocalModificationsForIsSendingVideo
        newState.hasLocalModificationsForActiveVideoCallParticipants = hasLocalModificationsForActiveVideoCallParticipants
        newState.hasLocalModificationsForReasonToLeave = hasLocalModificationsForReasonToLeave
        
        hasLocalModificationsForCallDeviceActive = false
        hasLocalModificationsForIgnoringCall = false
        hasLocalModificationsForActiveParticipants = false
        hasLocalModificationsForIsOutgoingCall = false
        hasLocalModificationsForTimedOut = false
        hasLocalModificationsForIsVideoCall = false
        hasLocalModificationsForIsSendingVideo = needsToSyncIsSendingVideo
        hasLocalModificationsForActiveVideoCallParticipants = false
        hasLocalModificationsForReasonToLeave = false
        
        newState.hasChanges = false
        return newState
    }
    
    /// returns true if the merge changed the current state
    public func mergeChangesFromState(other: ZMConversationCallState) {
        preserveHasChanges() {
            switch contextType {
            case .Sync: // Main -> Sync
                zmLog.debug("merge->sync other:\(other)")
                if other.hasLocalModificationsForCallDeviceActive {
                    isCallDeviceActive = other.isCallDeviceActive
                    hasLocalModificationsForCallDeviceActive = other.hasLocalModificationsForCallDeviceActive
                }
                if other.hasLocalModificationsForIsSendingVideo {
                    isSendingVideo = other.isSendingVideo
                    hasLocalModificationsForIsSendingVideo = other.hasLocalModificationsForIsSendingVideo
                    needsToSyncIsSendingVideo = false
                }
                if other.hasLocalModificationsForIgnoringCall {
                    isIgnoringCall = other.isIgnoringCall
                    hasLocalModificationsForIgnoringCall = isIgnoringCall ? other.hasLocalModificationsForIgnoringCall : false
                }
                if other.hasLocalModificationsForIsOutgoingCall {
                    isOutgoingCall = other.isOutgoingCall
                }
                if other.hasLocalModificationsForTimedOut {
                    timedOut = other.timedOut
                }
                if other.hasLocalModificationsForIsVideoCall {
                    isVideoCall = other.isVideoCall
                }
                if other.hasLocalModificationsForReasonToLeave {
                    reasonToLeave = other.reasonToLeave
                }

            case .Main: // Sync -> Main
                zmLog.debug("merge->main other:\(other)")
                if !hasLocalModificationsForCallDeviceActive {
                    isCallDeviceActive = other.isCallDeviceActive
                    hasLocalModificationsForCallDeviceActive = false
                }
                if  !hasLocalModificationsForIsSendingVideo {
                    isSendingVideo = other.isSendingVideo
                    hasLocalModificationsForIsSendingVideo = false
                }
                if !hasLocalModificationsForIsVideoCall {
                    isVideoCall = other.isVideoCall
                    hasLocalModificationsForIsVideoCall = false
                }
                if !hasLocalModificationsForIgnoringCall {
                    isIgnoringCall = other.isIgnoringCall
                    hasLocalModificationsForIgnoringCall = false
                }
                if other.hasLocalModificationsForActiveVideoCallParticipants {
                    activeVideoCallParticipants = other.activeVideoCallParticipants
                }
                if other.hasLocalModificationsForActiveParticipants {
                    activeFlowParticipants = other.activeFlowParticipants
                }
                if (other.hasLocalModificationsForReasonToLeave) {
                    reasonToLeave = other.reasonToLeave
                    hasLocalModificationsForReasonToLeave = false
                }
                isFlowActive = other.isFlowActive
                isOutgoingCall = other.isOutgoingCall
                
                if other.hasLocalModificationsForTimedOut {
                    timedOut = other.timedOut
                }
            }
        }
    }
    
    private func preserveHasChanges(@noescape block: () -> ()) {
        let oldHasChanges = hasChanges
        block()
        hasChanges = oldHasChanges
    }
    
    public override var description : String {
        return "CallState \(SwiftDebugging.address(self)) for contextType: \(contextType.description) \n" +
        " --> isCallDeviceActive: \(isCallDeviceActive) \n" +
        " --> hasLocalModificationsForCallDeviceActive: \(hasLocalModificationsForCallDeviceActive) \n" +
        " --> isIgnoringCall: \(isIgnoringCall) \n" +
        " --> hasLocalModificationsForIgnoringCall: \(hasLocalModificationsForIgnoringCall) \n" +
        " --> isFlowActive: \(isFlowActive) \n" +
        " --> activeFlowParticipants: \(activeFlowParticipants.mapWithBlock({$0.objectID})) \n" +
        " --> isOutgoingCall: \(isOutgoingCall) \n" +
        " --> hasLocalModificationsForActiveParticipants: \(hasLocalModificationsForActiveParticipants) \n" +
        " --> hasChanges: \(hasChanges) \n" +
        " --> isVideoCall: \(isVideoCall) \n" +
        " --> hasLocalModificationsForIsVideoCall: \(hasLocalModificationsForIsVideoCall) \n"
    }
    
    public override var debugDescription : String {
        return description
    }
}


extension ZMCallState {
    
    /// Before we merge, we copy out the state and reset `hasChanges`. If the receiver doesn't have changes
    /// this method returns nil.
    /// The returned copy can now be safely used on another context. The receiver (the original) has its "hasChanges" state reset.
    public func createCopyAndResetHasChanges() -> ZMCallState? {
        let newState = ZMCallState(contextType: contextType)
        
        for (moid, conversationState) in self {
            if (conversationState.hasChanges) {
                newState.conversationStates[moid] = conversationState.createCopy()
                conversationState.hasChanges = false
            }
        }
        return newState.isEmpty ? nil : newState
    }
    
    /// returns true if one of the merged states changed due to the merge
    public func mergeChangesFromState(other: ZMCallState?) -> Set<NSManagedObjectID> {
        if let other = other {
            for (moid, conversationState) in other {
                self.stateForConversationID(moid).mergeChangesFromState(conversationState)
            }
            return other.allObjectIDs
        }
        return Set()
    }
}
