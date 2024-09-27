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

final class MockVoiceChannel: NSObject, VoiceChannel {
    // MARK: Lifecycle

    required init(conversation: ZMConversation?) {
        self.conversation = conversation
    }

    // MARK: Internal

    var conversation: ZMConversation?
    var mockCallState: CallState = .incoming(video: false, shouldRing: true, degraded: false)
    var mockCallDuration: TimeInterval?
    var mockParticipants: [CallParticipant] = []
    var mockIsConstantBitRateAudioActive = false
    var mockInitiator: UserType?
    var mockIsVideoCall = false
    var mockVideoState: VideoState = .stopped
    var mockNetworkQuality: NetworkQuality = .normal
    var mockIsConferenceCall = false
    var mockFirstDegradedUser: UserType?

    var requestedCallParticipantsListKind: CallParticipantsListKind?
    var mockMuted = false
    var mockVideoGridPresentationMode: VideoGridPresentationMode = .allVideoStreams
    var requestedVideoStreams: [AVSClient]?

    var state: CallState {
        mockCallState
    }

    var callStartDate: Date? {
        if let mockCallDuration {
            Date(timeIntervalSinceNow: -mockCallDuration)
        } else {
            nil
        }
    }

    var participants: [CallParticipant] {
        mockParticipants
    }

    var isConstantBitRateAudioActive: Bool {
        mockIsConstantBitRateAudioActive
    }

    var isVideoCall: Bool {
        mockIsVideoCall
    }

    var initiator: UserType? {
        mockInitiator
    }

    var videoState: VideoState {
        get {
            mockVideoState
        }
        set {
            mockVideoState = newValue
        }
    }

    var networkQuality: NetworkQuality {
        mockNetworkQuality
    }

    var isConferenceCall: Bool {
        mockIsConferenceCall
    }

    var firstDegradedUser: UserType? {
        mockFirstDegradedUser
    }

    var muted: Bool {
        get {
            mockMuted
        }
        set {
            mockMuted = newValue
        }
    }

    var videoGridPresentationMode: VideoGridPresentationMode {
        get {
            mockVideoGridPresentationMode
        }
        set {
            mockVideoGridPresentationMode = newValue
        }
    }

    static func addCallStateObserver(_ observer: WireCallCenterCallStateObserver, userSession: ZMUserSession) -> Any {
        "token"
    }

    func addCallStateObserver(_: WireCallCenterCallStateObserver) -> Any {
        "token"
    }

    func addParticipantObserver(_: WireCallCenterCallParticipantObserver) -> Any {
        "token"
    }

    func addVoiceGainObserver(_: VoiceGainObserver) -> Any {
        "token"
    }

    func addConstantBitRateObserver(_: ConstantBitRateAudioObserver) -> Any {
        "token"
    }

    func addNetworkQualityObserver(_: NetworkQualityObserver) -> Any {
        "token"
    }

    func addMuteStateObserver(_: MuteStateObserver) -> Any {
        "token"
    }

    func addActiveSpeakersObserver(_: ActiveSpeakersObserver) -> Any {
        "token"
    }

    func participants(ofKind kind: CallParticipantsListKind, activeSpeakersLimit limit: Int?) -> [CallParticipant] {
        requestedCallParticipantsListKind = kind
        return mockParticipants
    }

    func setVideoCaptureDevice(_: CaptureDevice) throws {}

    func mute(_ muted: Bool, userSession: ZMUserSession) {}

    func join(video: Bool, userSession: ZMUserSession) -> Bool { true }

    func leave(userSession: ZMUserSession, completion: (() -> Void)?) {}

    func continueByDecreasingConversationSecurity(userSession: ZMUserSession) {}

    func join(video: Bool) -> Bool { true }

    func leave() {}

    func request(videoStreams: [AVSClient]) {
        requestedVideoStreams = videoStreams
    }
}
