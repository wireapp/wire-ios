//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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


protocol SelfPostingNotification {
    static var notificationName : Notification.Name { get }
}

extension SelfPostingNotification {
    static var userInfoKey : String { return notificationName.rawValue }
    
    func post() {
        NotificationCenter.default.post(name: type(of:self).notificationName,
                                        object: nil,
                                        userInfo: [type(of:self).userInfoKey : self])
    }
}



/// MARK - Video call observer

public typealias WireCallCenterObserverToken = NSObjectProtocol

struct WireCallCenterV3VideoNotification : SelfPostingNotification {
    static let notificationName = Notification.Name("WireCallCenterVideoNotification")
    
    let receivedVideoState : ReceivedVideoState
    
    init(receivedVideoState: ReceivedVideoState) {
        self.receivedVideoState = receivedVideoState
    }

}



/// MARK - Call state observer

public protocol WireCallCenterCallStateObserver : class {
    func callCenterDidChange(callState: CallState, conversationId: UUID, userId: UUID?)
}

public struct WireCallCenterCallStateNotification : SelfPostingNotification {
    static let notificationName = Notification.Name("WireCallCenterNotification")
    
    let callState : CallState
    let conversationId : UUID
    let userId : UUID?
}



/// MARK - Missed call observer

public protocol WireCallCenterMissedCallObserver : class {
    func callCenterMissedCall(conversationId: UUID, userId: UUID, timestamp: Date, video: Bool)
}

public struct WireCallCenterMissedCallNotification : SelfPostingNotification {
    static let notificationName = Notification.Name("WireCallCenterMissedCallNotification")
    
    let conversationId : UUID
    let userId : UUID
    let timestamp: Date
    let video: Bool
}



/// MARK - ConferenceParticipantsObserver
protocol WireCallCenterConferenceParticipantsObserver : class {
    func callCenterConferenceParticipantsChanged(conversationId: UUID, userIds: [UUID])
}

struct WireCallCenterConferenceParticipantsChangedNotification : SelfPostingNotification {
    static let notificationName = Notification.Name("WireCallCenterNotification")
    
    let conversationId : UUID
    let userId : UUID
    let timestamp: Date
    let video: Bool
}



/// MARK - CBR observer

public protocol WireCallCenterCBRCallObserver : class {
    func callCenterCallIsCBR()
}

struct WireCallCenterCBRCallNotification : SelfPostingNotification {
    static let notificationName = Notification.Name("WireCallCenterCBRCallNotification")
}


extension WireCallCenterV3 {
    
    // MARK - Observer
    
    /// Register observer of the call center call state. This will inform you when there's an incoming call etc.
    /// Returns a token which needs to unregistered with `removeObserver(token:)` to stop observing.
    public class func addCallStateObserver(observer: WireCallCenterCallStateObserver) -> WireCallCenterObserverToken  {
        return NotificationCenter.default.addObserver(forName: WireCallCenterCallStateNotification.notificationName, object: nil, queue: .main) { [weak observer] (note) in
            if let note = note.userInfo?[WireCallCenterCallStateNotification.userInfoKey] as? WireCallCenterCallStateNotification {
                observer?.callCenterDidChange(callState: note.callState, conversationId: note.conversationId, userId: note.userId)
            }
        }
    }
    
    /// Register observer of missed calls.
    /// Returns a token which needs to unregistered with `removeObserver(token:)` to stop observing.
    public class func addMissedCallObserver(observer: WireCallCenterMissedCallObserver) -> WireCallCenterObserverToken  {
        return NotificationCenter.default.addObserver(forName: WireCallCenterMissedCallNotification.notificationName, object: nil, queue: .main) { [weak observer] (note) in
            if let note = note.userInfo?[WireCallCenterMissedCallNotification.userInfoKey] as? WireCallCenterMissedCallNotification {
                observer?.callCenterMissedCall(conversationId: note.conversationId, userId: note.userId, timestamp: note.timestamp, video: note.video)
            }
        }
    }
    
    /// Register observer of the video state. This will inform you when the remote caller starts, stops sending video.
    /// Returns a token which needs to unregistered with `removeObserver(token:)` to stop observing.
    public class func addReceivedVideoObserver(observer: ReceivedVideoObserver) -> WireCallCenterObserverToken {
        return NotificationCenter.default.addObserver(forName: WireCallCenterV3VideoNotification.notificationName, object: nil, queue: .main) { [weak observer] (note) in
            if let note = note.userInfo?[WireCallCenterV3VideoNotification.userInfoKey] as? WireCallCenterV3VideoNotification {
                observer?.callCenterDidChange(receivedVideoState: note.receivedVideoState)
            }
        }
    }
    
    public class func removeObserver(token: WireCallCenterObserverToken) {
        NotificationCenter.default.removeObserver(token)
    }
    
}


class VoiceChannelParticipantV3Snapshot {
    
    fileprivate var state : SetSnapshot<CallMember>
    public private(set) var members : OrderedSetState<CallMember>
    
    fileprivate let conversationId : UUID
    fileprivate let selfUserID : UUID
    let initiator : UUID
    
    init(conversationId: UUID, selfUserID: UUID, members: [CallMember]?, initiator: UUID? = nil) {
        self.conversationId = conversationId
        self.selfUserID = selfUserID
        self.initiator = initiator ?? selfUserID
        
        guard let callCenter = WireCallCenterV3.activeInstance else {
            fatal("WireCallCenterV3 not accessible")
        }

        self.members = (members ?? callCenter.avsWrapper.members(in: conversationId)).toOrderedSetState()
        state = SetSnapshot(set: self.members, moveType: .uiCollectionView)
    }
    
    func callParticipantsChanged(newParticipants: [CallMember]) {
        var updated : Set<CallMember> = Set()
        var newMembers = [CallMember]()
        
        for m in newParticipants {
            if let idx = members.order[m], members.array[idx].audioEstablished != m.audioEstablished {
                updated.insert(m)
            }
            newMembers.append(m)
        }
        guard newMembers != members.array || updated.count > 0 else { return }
        
        members = newMembers.toOrderedSetState()
        recalculateSet(updated: updated)
    }
    
    /// calculate inserts / deletes / moves
    func recalculateSet(updated: Set<CallMember>) {
        guard let newStateUpdate = state.updatedState(updated,
                                                      observedObject: conversationId as NSUUID,
                                                      newSet: members)
        else { return}
        
        state = newStateUpdate.newSnapshot
        VoiceChannelParticipantNotification(setChangeInfo: newStateUpdate.changeInfo, conversationId: self.conversationId).post()
    }
    
    public func connectionState(forUserWith userId: UUID) -> VoiceChannelV2ConnectionState {
        let tempMember = CallMember(userId: userId, audioEstablished: false)
        guard let idx = members.order[tempMember] else {
            return .notConnected
        }
        let member = members.array[idx]
        return member.audioEstablished ? .connected : .connecting
    }
}
