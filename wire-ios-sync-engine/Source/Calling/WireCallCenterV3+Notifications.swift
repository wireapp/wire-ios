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

import Foundation

// MARK: - SelfPostingNotification

protocol SelfPostingNotification {
    static var notificationName: Notification.Name { get }
}

extension SelfPostingNotification {
    static var userInfoKey: String { notificationName.rawValue }

    func post(in context: NotificationContext, object: AnyObject? = nil) {
        NotificationInContext(
            name: type(of: self).notificationName,
            context: context,
            object: object,
            userInfo: [type(of: self).userInfoKey: self]
        ).post()
    }
}

// MARK: - NetworkQualityObserver

public protocol NetworkQualityObserver: AnyObject {
    func callCenterDidChange(networkQuality: NetworkQuality)
}

// MARK: - WireCallCenterNetworkQualityNotification

struct WireCallCenterNetworkQualityNotification: SelfPostingNotification {
    // MARK: Public

    public let conversationId: AVSIdentifier
    public let networkQuality: NetworkQuality

    // MARK: Internal

    static let notificationName = Notification.Name("WireCallCenterNetworkQualityNotification")
}

// MARK: - ConstantBitRateAudioObserver

public protocol ConstantBitRateAudioObserver: AnyObject {
    func callCenterDidChange(constantAudioBitRateAudioEnabled: Bool)
}

// MARK: - WireCallCenterCBRNotification

struct WireCallCenterCBRNotification: SelfPostingNotification {
    // MARK: Public

    public let enabled: Bool

    // MARK: Internal

    static let notificationName = Notification.Name("WireCallCenterCBRNotification")
}

// MARK: - MuteStateObserver

public protocol MuteStateObserver: AnyObject {
    func callCenterDidChange(muted: Bool)
}

// MARK: - WireCallCenterMutedNotification

struct WireCallCenterMutedNotification: SelfPostingNotification {
    // MARK: Public

    public let muted: Bool

    // MARK: Internal

    static let notificationName = Notification.Name("WireCallCenterMutedNotification")
}

// MARK: - ConferenceCallingUnavailableObserver

public protocol ConferenceCallingUnavailableObserver: AnyObject {
    func callCenterDidNotStartConferenceCall()
}

// MARK: - WireCallCenterConferenceCallingUnavailableNotification

struct WireCallCenterConferenceCallingUnavailableNotification: SelfPostingNotification {
    static let notificationName = Notification.Name("WireCallCenterConferenceCallingUnavailableNotification")
}

// MARK: - ActiveSpeakersObserver

public protocol ActiveSpeakersObserver: AnyObject {
    func callCenterDidChangeActiveSpeakers()
}

// MARK: - WireCallCenterActiveSpeakersNotification

struct WireCallCenterActiveSpeakersNotification: SelfPostingNotification {
    static let notificationName = Notification.Name("WireCallCenterActiveSpeakersNotification")
}

// MARK: - WireCallCenterCallStateObserver

public protocol WireCallCenterCallStateObserver: AnyObject {
    /// Called when the callState changes in a conversation
    ///
    /// - parameter callState: updated state
    /// - parameter conversation: where the call is ongoing
    /// - parameter caller: user which initiated the call
    /// - parameter timestamp: when the call state change occured
    func callCenterDidChange(
        callState: CallState,
        conversation: ZMConversation,
        caller: UserType,
        timestamp: Date?,
        previousCallState: CallState?
    )
}

// MARK: - WireCallCenterCallStateNotification

public struct WireCallCenterCallStateNotification: SelfPostingNotification {
    static let notificationName = Notification.Name("WireCallCenterNotification")

    weak var context: NSManagedObjectContext?
    let callState: CallState
    let conversationId: AVSIdentifier
    let callerId: AVSIdentifier
    let messageTime: Date?
    let previousCallState: CallState?
}

// MARK: - WireCallCenterMissedCallObserver

public protocol WireCallCenterMissedCallObserver: AnyObject {
    func callCenterMissedCall(conversation: ZMConversation, caller: UserType, timestamp: Date, video: Bool)
}

// MARK: - WireCallCenterMissedCallNotification

public struct WireCallCenterMissedCallNotification: SelfPostingNotification {
    static let notificationName = Notification.Name("WireCallCenterMissedCallNotification")

    weak var context: NSManagedObjectContext?
    let conversationId: AVSIdentifier
    let callerId: AVSIdentifier
    let timestamp: Date
    let video: Bool
}

// MARK: - WireCallCenterCallErrorObserver

public protocol WireCallCenterCallErrorObserver: AnyObject {
    func callCenterDidReceiveCallError(_ error: CallError, conversationId: AVSIdentifier)
}

// MARK: - WireCallCenterCallErrorNotification

public struct WireCallCenterCallErrorNotification: SelfPostingNotification {
    static let notificationName = Notification.Name("WireCallCenterCallErrorNotification")

    weak var context: NSManagedObjectContext?

    let error: CallError
    let conversationId: AVSIdentifier
}

// MARK: - WireCallCenterCallParticipantObserver

public protocol WireCallCenterCallParticipantObserver: AnyObject {
    /// Called when a participant of the call joins / leaves or when their call state changes
    ///
    /// - parameter conversation: where the call is ongoing
    /// - parameter particpants: updated list of call participants
    func callParticipantsDidChange(conversation: ZMConversation, participants: [CallParticipant])
}

// MARK: - WireCallCenterCallParticipantNotification

public struct WireCallCenterCallParticipantNotification: SelfPostingNotification {
    static let notificationName = Notification.Name("VoiceChannelParticipantNotification")

    let conversationId: AVSIdentifier
    let participants: [CallParticipant]
}

// MARK: - VoiceGainObserver

public protocol VoiceGainObserver: AnyObject {
    func voiceGainDidChange(forParticipant participant: UserType, volume: Float)
}

// MARK: - VoiceGainNotification

public class VoiceGainNotification: SelfPostingNotification {
    // MARK: Lifecycle

    init(volume: Float, conversationId: AVSIdentifier, userId: AVSIdentifier) {
        self.volume = volume
        self.conversationId = conversationId
        self.userId = userId
    }

    // MARK: Internal

    static let notificationName = Notification.Name("VoiceGainNotification")
    static let userInfoKey = notificationName.rawValue

    let volume: Float
    let userId: AVSIdentifier
    let conversationId: AVSIdentifier
}

extension WireCallCenterV3 {
    // MARK: - Observer

    public class func addCallErrorObserver(
        observer: WireCallCenterCallErrorObserver,
        userSession: ZMUserSession
    ) -> Any {
        addCallErrorObserver(observer: observer, context: userSession.managedObjectContext)
    }

    class func addCallErrorObserver(observer: WireCallCenterCallErrorObserver, context: NSManagedObjectContext) -> Any {
        NotificationInContext.addObserver(
            name: WireCallCenterCallErrorNotification.notificationName,
            context: context.notificationContext,
            queue: .main
        ) { [weak observer] note in
            if let note = note
                .userInfo[WireCallCenterCallErrorNotification.userInfoKey] as? WireCallCenterCallErrorNotification {
                observer?.callCenterDidReceiveCallError(note.error, conversationId: note.conversationId)
            }
        }
    }

    /// Register observer of the call center call state. This will inform you when there's an incoming call etc.
    /// Returns a token which needs to be retained as long as the observer should be active.
    public class func addCallStateObserver(
        observer: WireCallCenterCallStateObserver,
        userSession: ZMUserSession
    ) -> Any {
        addCallStateObserver(observer: observer, context: userSession.managedObjectContext)
    }

    /// Register observer of the call center call state in all user sessions.
    /// Returns a token which needs to be retained as long as the observer should be active.
    class func addGlobalCallStateObserver(observer: WireCallCenterCallStateObserver) -> Any {
        NotificationInContext.addUnboundedObserver(
            name: WireCallCenterCallStateNotification.notificationName,
            context: nil
        ) { [weak observer] note in
            if let note = note
                .userInfo[WireCallCenterCallStateNotification.userInfoKey] as? WireCallCenterCallStateNotification,
                let context = note.context,
                let caller = ZMUser.fetch(
                    with: note.callerId.identifier,
                    domain: note.callerId.domain,
                    in: context
                ),
                let conversation = ZMConversation.fetch(
                    with: note.conversationId.identifier,
                    domain: note.conversationId.domain,
                    in: context
                ) {
                observer?.callCenterDidChange(
                    callState: note.callState,
                    conversation: conversation,
                    caller: caller,
                    timestamp: note.messageTime,
                    previousCallState: note.previousCallState
                )
            }
        }
    }

    /// Register observer of the call center call state. This will inform you when there's an incoming call etc.
    /// Returns a token which needs to be retained as long as the observer should be active.
    class func addCallStateObserver(observer: WireCallCenterCallStateObserver, context: NSManagedObjectContext) -> Any {
        NotificationInContext.addObserver(
            name: WireCallCenterCallStateNotification.notificationName,
            context: context.notificationContext,
            queue: .main
        ) { [weak observer] note in
            if let note = note
                .userInfo[WireCallCenterCallStateNotification.userInfoKey] as? WireCallCenterCallStateNotification,
                let caller = ZMUser.fetch(
                    with: note.callerId.identifier,
                    domain: note.callerId.domain,
                    in: context
                ),
                let conversation = ZMConversation.fetch(
                    with: note.conversationId.identifier,
                    domain: note.conversationId.domain,
                    in: context
                ) {
                observer?.callCenterDidChange(
                    callState: note.callState,
                    conversation: conversation,
                    caller: caller,
                    timestamp: note.messageTime,
                    previousCallState: note.previousCallState
                )
            }
        }
    }

    /// Register observer of the call center call state. This will inform you when there's an incoming call etc.
    /// Returns a token which needs to be retained as long as the observer should be active.
    public class func addCallStateObserver(
        observer: WireCallCenterCallStateObserver,
        for conversation: ZMConversation,
        userSession: ZMUserSession
    ) -> Any {
        addCallStateObserver(observer: observer, for: conversation, context: userSession.managedObjectContext)
    }

    /// Register observer of the call center call state. This will inform you when there's an incoming call etc.
    /// Returns a token which needs to be retained as long as the observer should be active.
    class func addCallStateObserver(
        observer: WireCallCenterCallStateObserver,
        for conversation: ZMConversation,
        context: NSManagedObjectContext
    ) -> Any {
        NotificationInContext.addObserver(
            name: WireCallCenterCallStateNotification.notificationName,
            context: context.notificationContext,
            queue: .main
        ) { [weak observer] note in
            if let note = note
                .userInfo[WireCallCenterCallStateNotification.userInfoKey] as? WireCallCenterCallStateNotification,
                let caller = ZMUser.fetch(
                    with: note.callerId.identifier,
                    domain: note.callerId.domain,
                    in: context
                ),
                note.conversationId == conversation.avsIdentifier {
                observer?.callCenterDidChange(
                    callState: note.callState,
                    conversation: conversation,
                    caller: caller,
                    timestamp: note.messageTime,
                    previousCallState: note.previousCallState
                )
            }
        }
    }

    /// Register observer of missed calls.
    /// Returns a token which needs to be retained as long as the observer should be active.
    public class func addMissedCallObserver(
        observer: WireCallCenterMissedCallObserver,
        userSession: ZMUserSession
    ) -> Any {
        addMissedCallObserver(observer: observer, context: userSession.managedObjectContext)
    }

    /// Register observer of missed calls.
    /// Returns a token which needs to be retained as long as the observer should be active.
    class func addMissedCallObserver(
        observer: WireCallCenterMissedCallObserver,
        context: NSManagedObjectContext
    ) -> Any {
        NotificationInContext.addObserver(
            name: WireCallCenterMissedCallNotification.notificationName,
            context: context.notificationContext,
            queue: .main
        ) { [weak observer] note in
            if let note = note
                .userInfo[
                    WireCallCenterMissedCallNotification
                        .userInfoKey
                ] as? WireCallCenterMissedCallNotification,
                let caller = ZMUser.fetch(
                    with: note.callerId.identifier,
                    domain: note.callerId.domain,
                    in: context
                ),
                let conversation = ZMConversation.fetch(
                    with: note.conversationId.identifier,
                    domain: note.conversationId.domain,
                    in: context
                ) {
                observer?.callCenterMissedCall(
                    conversation: conversation,
                    caller: caller,
                    timestamp: note.timestamp,
                    video: note.video
                )
            }
        }
    }

    /// Register observer of missed calls for in all user sessions
    /// Returns a token which needs to be retained as long as the observer should be active.
    class func addGlobalMissedCallObserver(observer: WireCallCenterMissedCallObserver) -> Any {
        NotificationInContext.addUnboundedObserver(
            name: WireCallCenterMissedCallNotification.notificationName,
            context: nil
        ) { [weak observer] note in
            if let note = note
                .userInfo[
                    WireCallCenterMissedCallNotification
                        .userInfoKey
                ] as? WireCallCenterMissedCallNotification,
                let context = note.context,
                let caller = ZMUser.fetch(
                    with: note.callerId.identifier,
                    domain: note.callerId.domain,
                    in: context
                ),
                let conversation = ZMConversation.fetch(
                    with: note.conversationId.identifier,
                    domain: note.conversationId.domain,
                    in: context
                ) {
                observer?.callCenterMissedCall(
                    conversation: conversation,
                    caller: caller,
                    timestamp: note.timestamp,
                    video: note.video
                )
            }
        }
    }

    /// Register observer when constant audio bit rate is enabled/disabled
    /// Returns a token which needs to be retained as long as the observer should be active.
    public class func addConstantBitRateObserver(
        observer: ConstantBitRateAudioObserver,
        userSession: ZMUserSession
    ) -> Any {
        addConstantBitRateObserver(observer: observer, context: userSession.managedObjectContext)
    }

    /// Register observer when constant audio bit rate is enabled/disabled
    /// Returns a token which needs to be retained as long as the observer should be active.
    class func addConstantBitRateObserver(
        observer: ConstantBitRateAudioObserver,
        context: NSManagedObjectContext
    ) -> Any {
        NotificationInContext.addObserver(
            name: WireCallCenterCBRNotification.notificationName,
            context: context.notificationContext,
            queue: .main
        ) { [weak observer] note in
            if let note = note
                .userInfo[WireCallCenterCBRNotification.userInfoKey] as? WireCallCenterCBRNotification {
                observer?.callCenterDidChange(constantAudioBitRateAudioEnabled: note.enabled)
            }
        }
    }

    /// Add observer of particpants in a voice channel. Returns a token which needs to be retained as long as the
    /// observer should be active.
    /// Returns a token which needs to be retained as long as the observer should be active.
    public class func addCallParticipantObserver(
        observer: WireCallCenterCallParticipantObserver,
        for conversation: ZMConversation,
        userSession: ZMUserSession
    ) -> Any {
        addCallParticipantObserver(observer: observer, for: conversation, context: userSession.managedObjectContext)
    }

    /// Add observer of call particpants in a conversation. Returns a token which needs to be retained as long as the
    /// observer should be active.
    /// Returns a token which needs to be retained as long as the observer should be active.
    class func addCallParticipantObserver(
        observer: WireCallCenterCallParticipantObserver,
        for conversation: ZMConversation,
        context: NSManagedObjectContext
    ) -> Any {
        NotificationInContext.addObserver(
            name: WireCallCenterCallParticipantNotification.notificationName,
            context: context.notificationContext,
            queue: .main
        ) { [weak observer] note in
            guard
                let note = note
                .userInfo[
                    WireCallCenterCallParticipantNotification
                        .userInfoKey
                ] as? WireCallCenterCallParticipantNotification,
                let observer,
                note.conversationId == conversation.avsIdentifier
            else {
                return
            }

            observer.callParticipantsDidChange(conversation: conversation, participants: note.participants)
        }
    }

    /// Add observer of voice gain. Returns a token which needs to be retained as long as the observer should be active.
    /// Returns a token which needs to be retained as long as the observer should be active.
    public class func addVoiceGainObserver(
        observer: VoiceGainObserver,
        for conversation: ZMConversation,
        userSession: ZMUserSession
    ) -> Any {
        addVoiceGainObserver(observer: observer, for: conversation, context: userSession.managedObjectContext)
    }

    /// Add observer of voice gain. Returns a token which needs to be retained as long as the observer should be active.
    /// Returns a token which needs to be retained as long as the observer should be active.
    class func addVoiceGainObserver(
        observer: VoiceGainObserver,
        for conversation: ZMConversation,
        context: NSManagedObjectContext
    ) -> Any {
        NotificationInContext.addObserver(
            name: VoiceGainNotification.notificationName,
            context: context.notificationContext,
            queue: .main
        ) { [weak observer] note in
            guard
                let note = note.userInfo[VoiceGainNotification.userInfoKey] as? VoiceGainNotification,
                let observer,
                let user = ZMUser.fetch(
                    with: note.userId.identifier,
                    domain: note.userId.domain,
                    in: context
                )
            else {
                return
            }
            observer.voiceGainDidChange(forParticipant: user, volume: note.volume)
        }
    }

    /// Register observer when network quality changes
    /// Returns a token which needs to be retained as long as the observer should be active.
    public class func addNetworkQualityObserver(
        observer: NetworkQualityObserver,
        for conversation: ZMConversation,
        userSession: ZMUserSession
    ) -> Any {
        addNetworkQualityObserver(observer: observer, for: conversation, context: userSession.managedObjectContext)
    }

    /// Register observer when network quality changes
    /// Returns a token which needs to be retained as long as the observer should be active.
    class func addNetworkQualityObserver(
        observer: NetworkQualityObserver,
        for conversation: ZMConversation,
        context: NSManagedObjectContext
    ) -> Any {
        NotificationInContext.addObserver(
            name: WireCallCenterNetworkQualityNotification.notificationName,
            context: context.notificationContext,
            queue: .main
        ) { [weak observer] note in
            if let note = note
                .userInfo[
                    WireCallCenterNetworkQualityNotification
                        .userInfoKey
                ] as? WireCallCenterNetworkQualityNotification {
                if note.conversationId == conversation.avsIdentifier {
                    observer?.callCenterDidChange(networkQuality: note.networkQuality)
                }
            }
        }
    }

    /// Add observer of mute state. Returns a token which needs to be retained as long as the observer should be active.
    /// Returns a token which needs to be retained as long as the observer should be active.
    public class func addMuteStateObserver(observer: MuteStateObserver, userSession: ZMUserSession) -> Any {
        addMuteStateObserver(observer: observer, context: userSession.managedObjectContext)
    }

    /// Add observer of mute state. Returns a token which needs to be retained as long as the observer should be active.
    /// Returns a token which needs to be retained as long as the observer should be active.
    class func addMuteStateObserver(observer: MuteStateObserver, context: NSManagedObjectContext) -> Any {
        NotificationInContext.addObserver(
            name: WireCallCenterMutedNotification.notificationName,
            context: context.notificationContext,
            object: nil,
            queue: .main
        ) { [weak observer] note in
            guard let note = note
                .userInfo[WireCallCenterMutedNotification.userInfoKey] as? WireCallCenterMutedNotification,
                let observer
            else {
                return
            }
            observer.callCenterDidChange(muted: note.muted)
        }
    }

    public class func addActiveSpeakersObserver(
        observer: ActiveSpeakersObserver,
        context: NSManagedObjectContext
    ) -> Any {
        NotificationInContext.addObserver(
            name: WireCallCenterActiveSpeakersNotification.notificationName,
            context: context.notificationContext
        ) { [weak observer] _ in
            observer?.callCenterDidChangeActiveSpeakers()
        }
    }

    /// Add an observer for conference calling unavailable events.
    ///
    /// - Returns: A token which needs to be retained as long as the observer should be active.

    public class func addConferenceCallingUnavailableObserver(
        observer: ConferenceCallingUnavailableObserver,
        userSession: ZMUserSession
    ) -> Any {
        NotificationInContext.addObserver(
            name: WireCallCenterConferenceCallingUnavailableNotification.notificationName,
            context: userSession.managedObjectContext.notificationContext,
            using: { [weak observer] _ in
                observer?.callCenterDidNotStartConferenceCall()
            }
        )
    }
}
