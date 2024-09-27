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

// MARK: - VoiceChannelV3Error

public enum VoiceChannelV3Error: LocalizedError {
    case switchToVideoNotAllowed

    // MARK: Public

    public var errorDescription: String? {
        switch self {
        case .switchToVideoNotAllowed:
            "Switch to video is not allowed"
        }
    }
}

// MARK: - VoiceChannelV3

public class VoiceChannelV3: NSObject, VoiceChannel {
    // MARK: Lifecycle

    public required init(conversation: ZMConversation) {
        self.conversation = conversation
        super.init()
    }

    // MARK: Public

    public weak var conversation: ZMConversation?

    public var callCenter: WireCallCenterV3? {
        conversation?.managedObjectContext?.zm_callCenter
    }

    /// The date and time of current call start
    public var callStartDate: Date? {
        callCenter?.establishedDate
    }

    public var participants: [CallParticipant] {
        participants(ofKind: .all, activeSpeakersLimit: nil)
    }

    public var state: CallState {
        guard
            let conversationId = conversation?.avsIdentifier,
            let callCenter
        else { return .none }

        return callCenter.callState(conversationId: conversationId)
    }

    public var isVideoCall: Bool {
        guard
            let conversationId = conversation?.avsIdentifier,
            let callCenter
        else { return false }

        return callCenter.isVideoCall(conversationId: conversationId)
    }

    public var isConstantBitRateAudioActive: Bool {
        guard
            let conversationId = conversation?.avsIdentifier,
            let callCenter
        else { return false }

        return callCenter.isContantBitRate(conversationId: conversationId)
    }

    public var networkQuality: NetworkQuality {
        guard
            let conversationId = conversation?.avsIdentifier,
            let callCenter
        else { return .normal }

        return callCenter.networkQuality(conversationId: conversationId)
    }

    public var initiator: UserType? {
        guard let context = conversation?.managedObjectContext,
              let convId = conversation?.avsIdentifier,
              let userId = callCenter?.initiatorForCall(conversationId: convId)
        else {
            return nil
        }
        return ZMUser.fetch(with: userId.identifier, domain: userId.domain, in: context)
    }

    public var videoState: VideoState {
        get {
            guard
                let conversationId = conversation?.avsIdentifier,
                let callCenter
            else { return .stopped }

            return callCenter.videoState(conversationId: conversationId)
        }
        set {
            guard let conversationId = conversation?.avsIdentifier else { return }

            callCenter?.setVideoState(conversationId: conversationId, videoState: newValue)
        }
    }

    public var muted: Bool {
        get { callCenter?.isMuted ?? false }
        set { callCenter?.isMuted = newValue }
    }

    public var isConferenceCall: Bool {
        guard
            let conversationId = conversation?.avsIdentifier,
            let callCenter
        else { return false }

        return callCenter.isConferenceCall(conversationId: conversationId)
    }

    public var firstDegradedUser: UserType? {
        guard
            let conversationId = conversation?.avsIdentifier,
            let degradedUser = callCenter?.degradedUser(conversationId: conversationId)
        else {
            return conversation?.localParticipants.first(where: {
                !$0.isTrusted
            })
        }

        return degradedUser
    }

    public var videoGridPresentationMode: VideoGridPresentationMode {
        get {
            guard
                let conversationId = conversation?.avsIdentifier,
                let callCenter
            else {
                return .allVideoStreams
            }
            return callCenter.videoGridPresentationMode(conversationId: conversationId)
        }
        set {
            guard let conversationId = conversation?.avsIdentifier else { return }
            callCenter?.setVideoGridPresentationMode(newValue, for: conversationId)
        }
    }

    public func participants(
        ofKind kind: CallParticipantsListKind,
        activeSpeakersLimit limit: Int?
    ) -> [CallParticipant] {
        guard
            let callCenter,
            let conversationId = conversation?.avsIdentifier
        else { return [] }

        return callCenter.callParticipants(conversationId: conversationId, kind: kind, activeSpeakersLimit: limit)
    }

    public func setVideoCaptureDevice(_ device: CaptureDevice) throws {
        guard let conversationId = conversation?.avsIdentifier else {
            throw VoiceChannelV3Error.switchToVideoNotAllowed
        }

        callCenter?.setVideoCaptureDevice(device, for: conversationId)
    }
}

// MARK: CallActions

extension VoiceChannelV3: CallActions {
    public func mute(_ muted: Bool, userSession: ZMUserSession) {
        if userSession.callNotificationStyle == .callKit {
            userSession.callKitManager?.requestMuteCall(in: conversation!, muted: muted)
        } else {
            self.muted = muted
        }
    }

    public func continueByDecreasingConversationSecurity(userSession: ZMUserSession) {
        guard let conversation else { return }
        conversation.acknowledgePrivacyWarningAndResendMessages()
    }

    public func join(video: Bool, userSession: ZMUserSession) -> Bool {
        if userSession.callNotificationStyle == .callKit {
            userSession.callKitManager?.requestJoinCall(in: conversation!, video: video)
            return true
        } else {
            return join(video: video)
        }
    }

    public func leave(userSession: ZMUserSession, completion: (() -> Void)?) {
        if userSession.callNotificationStyle == .callKit {
            userSession.callKitManager?.requestEndCall(in: conversation!, completion: completion)
        } else {
            leave()
            completion?()
        }
    }

    public func request(videoStreams: [AVSClient]) {
        guard let conversationId = conversation?.avsIdentifier else { return }

        callCenter?.requestVideoStreams(conversationId: conversationId, clients: videoStreams)
    }
}

// MARK: CallActionsInternal

extension VoiceChannelV3: CallActionsInternal {
    public func join(video: Bool) -> Bool {
        guard
            let conversation,
            let callCenter
        else {
            return false
        }

        do {
            switch state {
            case .incoming:
                try callCenter.answerCall(conversation: conversation, video: video)
                return true

            default:
                try callCenter.startCall(in: conversation, isVideo: video)
                return true
            }
        } catch {
            return false
        }
    }

    public func leave() {
        guard let conversationId = conversation?.avsIdentifier else { return }

        switch state {
        case .incoming:
            callCenter?.rejectCall(conversationId: conversationId)
        default:
            callCenter?.closeCall(conversationId: conversationId)
        }
    }
}

// MARK: CallObservers

extension VoiceChannelV3: CallObservers {
    public func addNetworkQualityObserver(_ observer: NetworkQualityObserver) -> Any {
        WireCallCenterV3.addNetworkQualityObserver(
            observer: observer,
            for: conversation!,
            context: conversation!.managedObjectContext!
        )
    }

    /// Add observer of voice channel state. Returns a token which needs to be retained as long as the observer should
    /// be active.
    public func addCallStateObserver(_ observer: WireCallCenterCallStateObserver) -> Any {
        WireCallCenterV3.addCallStateObserver(
            observer: observer,
            for: conversation!,
            context: conversation!.managedObjectContext!
        )
    }

    /// Add observer of voice channel participants. Returns a token which needs to be retained as long as the observer
    /// should be active.
    public func addParticipantObserver(_ observer: WireCallCenterCallParticipantObserver) -> Any {
        WireCallCenterV3.addCallParticipantObserver(
            observer: observer,
            for: conversation!,
            context: conversation!.managedObjectContext!
        )
    }

    /// Add observer of voice gain. Returns a token which needs to be retained as long as the observer should be active.
    public func addVoiceGainObserver(_ observer: VoiceGainObserver) -> Any {
        WireCallCenterV3.addVoiceGainObserver(
            observer: observer,
            for: conversation!,
            context: conversation!.managedObjectContext!
        )
    }

    /// Add observer of constant bit rate audio. Returns a token which needs to be retained as long as the observer
    /// should be active.
    public func addConstantBitRateObserver(_ observer: ConstantBitRateAudioObserver) -> Any {
        WireCallCenterV3.addConstantBitRateObserver(observer: observer, context: conversation!.managedObjectContext!)
    }

    /// Add observer of the state of all voice channels. Returns a token which needs to be retained as long as the
    /// observer should be active.
    public class func addCallStateObserver(
        _ observer: WireCallCenterCallStateObserver,
        userSession: ZMUserSession
    ) -> Any {
        WireCallCenterV3.addCallStateObserver(observer: observer, context: userSession.managedObjectContext)
    }

    /// Add observer of the mute state. Returns a token which needs to be retained as long as the observer should be
    /// active.
    public func addMuteStateObserver(_ observer: MuteStateObserver) -> Any {
        WireCallCenterV3.addMuteStateObserver(observer: observer, context: conversation!.managedObjectContext!)
    }

    public func addActiveSpeakersObserver(_ observer: ActiveSpeakersObserver) -> Any {
        WireCallCenterV3.addActiveSpeakersObserver(observer: observer, context: conversation!.managedObjectContext!)
    }
}
