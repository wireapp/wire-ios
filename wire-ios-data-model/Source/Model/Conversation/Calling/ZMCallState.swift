//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

import CoreData
import Foundation
import WireSystem

private let zmLog = ZMSLog(tag: "CallState")

private let UserInfoCallStateKey = "ZMCallState"
private let UserInfoHasChangesKey = "zm_userInfoHasChanges"

extension NSManagedObjectContext {
    @objc public var zm_callState: ZMCallState {
        let oldState = userInfo[UserInfoCallStateKey] as? ZMCallState
        return oldState ?? { () -> ZMCallState in
            let state = ZMCallState()
            self.userInfo[UserInfoCallStateKey] = state
            return state
        }()
    }

    @objc
    public func zm_tearDownCallState() {
        if (userInfo[UserInfoCallStateKey] as? ZMCallState) != nil {
            userInfo.removeObject(forKey: UserInfoCallStateKey)
        }
    }

    /// True if the context has some changes in the user info that should cause a save
    @objc public var zm_hasUserInfoChanges: Bool {
        get {
            (userInfo[UserInfoHasChangesKey] as? Bool) ?? false
        }
        set {
            userInfo[UserInfoHasChangesKey] = newValue
        }
    }

    /// Checks hasChanges and callStateHasChanges.
    ///
    /// The call state changes do not dirty the context's objects, hence need to be tracked / checked seperately.
    @objc public var zm_hasChanges: Bool {
        hasChanges || zm_hasUserInfoChanges
    }

    @objc
    public func mergeCallStateChanges(fromUserInfo userInfo: [String: Any]) {
        guard zm_isSyncContext else {
            return
        } // we don't merge anything to UI, UI is autoritative

        if let callState = self.userInfo[UserInfoCallStateKey] as? ZMCallState {
            _ = callState.mergeChangesFromState(userInfo[UserInfoCallStateKey] as? ZMCallState)
        }
    }
}

// MARK: Group Calling V3

// This needs to be set to display the correct conversationListIndicator
extension ZMConversation {
    var callState: ZMConversationCallState {
        managedObjectContext!.zm_callState.stateForConversation(self)
    }

    @objc public var isIgnoringCall: Bool {
        get {
            callState.isIgnoringCall
        }
        set {
            if callState.isIgnoringCall != newValue {
                callState.isIgnoringCall = newValue
                managedObjectContext?.zm_hasUserInfoChanges = true
            }
        }
    }

    @objc public var isCallDeviceActive: Bool {
        get {
            callState.isCallDeviceActive
        }
        set {
            if callState.isCallDeviceActive != newValue {
                callState.isCallDeviceActive = newValue
                managedObjectContext?.zm_hasUserInfoChanges = true
            }
        }
    }
}

// MARK: - ZMCallState

@objc
open class ZMCallState: NSObject, Sequence {
    // MARK: Open

    open var isEmpty: Bool {
        conversationStates.isEmpty
    }

    override open var description: String {
        "CallState \(SwiftDebugging.address(self)) \n" +
            " --> states : \(conversationStates) \n"
    }

    override open var debugDescription: String {
        description
    }

    open func allContainedConversationsInContext(_ moc: NSManagedObjectContext) -> Set<ZMConversation> {
        var r = Set<ZMConversation>()
        for oid in allObjectIDs {
            r.insert(moc.object(with: oid) as! ZMConversation)
        }
        return r
    }

    open func stateForConversation(_ conversation: NSManagedObject) -> ZMConversationCallState {
        if conversation.objectID.isTemporaryID {
            do {
                try conversation.managedObjectContext!.obtainPermanentIDs(for: [conversation])
            } catch let err {
                fatal("Could not obtain permanent object ID from conversation - error: \(err)")
            }
        }
        return stateForConversationID(conversation.objectID)
    }

    open func makeIterator() -> Iterator {
        conversationStates.makeIterator()
    }

    // MARK: Public

    public typealias Iterator = DictionaryIterator<NSManagedObjectID, ZMConversationCallState>

    // MARK: Internal

    func stateForConversationID(_ conversationID: NSManagedObjectID) -> ZMConversationCallState {
        conversationStates[conversationID] ?? {
            zmLog.debug("inserting new state for conversationID \(conversationID) into \(SwiftDebugging.address(self))")
            let newState = ZMConversationCallState()
            self.conversationStates[conversationID] = newState
            return newState
        }()
    }

    // MARK: Fileprivate

    fileprivate var conversationStates: [NSManagedObjectID: ZMConversationCallState] = [:]

    fileprivate var allObjectIDs: Set<NSManagedObjectID> {
        Set(conversationStates.keys)
    }
}

// MARK: - ZMConversationCallState

/// This is the call state for a specific conversation.
open class ZMConversationCallState: NSObject {
    open var isCallDeviceActive = false
    open var isIgnoringCall = false

    override open var description: String {
        "CallState \(SwiftDebugging.address(self)) \n" +
            " --> isCallDeviceActive: \(isCallDeviceActive) \n"
    }

    override open var debugDescription: String {
        description
    }

    /// returns true if the merge changed the current state
    open func mergeChangesFromState(_ other: ZMConversationCallState) {
        isCallDeviceActive = other.isCallDeviceActive
        isIgnoringCall = other.isIgnoringCall
    }
}

extension ZMCallState {
    /// returns true if one of the merged states changed due to the merge
    public func mergeChangesFromState(_ other: ZMCallState?) -> Set<NSManagedObjectID> {
        if let other {
            for (moid, conversationState) in other {
                stateForConversationID(moid).mergeChangesFromState(conversationState)
            }
            return other.allObjectIDs
        }
        return Set()
    }
}
