//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

import Combine
import UIKit
import WireDataModel
import WireLogging
import WireSyncEngine

final class CallingContainerViewModel: ObservableObject {

    @Published var callInfoConfiguration: CallInfoConfiguration?
    @Published var isIncomingCall: Bool = false
    @Published var isPanEnabled: Bool = true
    @Published var participants: CallParticipantsList = []
    /// Bumped when the active voice channel changes; used as `.id` on CallViewControllerRepresentable to force recreation.
    @Published private(set) var voiceChannelRevision: UUID = UUID()

    var onHideCallView: () -> Void = {}

    private(set) var voiceChannel: VoiceChannel
    let userSession: UserSession
    /// Set by CallViewControllerRepresentable after the CallViewController is created.
    weak var callViewController: CallViewController?

    private var callStateObserverToken: Any?
    private var participantsObserverToken: Any?
    private weak var callDurationTimer: Timer?

    init(voiceChannel: VoiceChannel, userSession: UserSession) {
        self.voiceChannel = voiceChannel
        self.userSession = userSession
        self.participants = voiceChannel.getParticipantsList()
    }

    deinit {
        stopCallDurationTimer()
    }

    func startObserving() {
        guard userSession is ZMUserSession else {
            WireLogger.calling.error("UserSession not available when initializing \(type(of: self))")
            return
        }
        callStateObserverToken = WireCallCenterV3.addCallStateObserver(
            observer: self,
            contextProvider: userSession.contextProvider
        )
        participantsObserverToken = voiceChannel.addParticipantObserver(self)
    }

    func didUpdateConfiguration(_ configuration: CallInfoConfiguration) {
        let stateChanged = configuration.state != callInfoConfiguration?.state
        if stateChanged {
            switch configuration.state {
            case .established: startCallDurationTimer()
            case .terminating: stopCallDurationTimer()
            default: break
            }
        }
        callInfoConfiguration = configuration
        isIncomingCall = configuration.state.isIncoming
        isPanEnabled = !configuration.state.isIncoming
    }

    func updateVoiceChannelIfNeeded() {
        guard
            let conversation = (userSession as? ZMUserSession)?.priorityCallConversation,
            voiceChannel.conversation != conversation,
            let newVoiceChannel = conversation.voiceChannel
        else { return }

        voiceChannel = newVoiceChannel
        participants = newVoiceChannel.getParticipantsList()
        participantsObserverToken = newVoiceChannel.addParticipantObserver(self)
        voiceChannelRevision = UUID()
    }

    private func startCallDurationTimer() {
        stopCallDurationTimer()
        callDurationTimer = .scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self,
                  let configuration = callInfoConfiguration,
                  case .established = configuration.state else { return }
            callInfoConfiguration = configuration
        }
    }

    private func stopCallDurationTimer() {
        callDurationTimer?.invalidate()
        callDurationTimer = nil
    }
}

// MARK: - WireCallCenterCallStateObserver

extension CallingContainerViewModel: WireCallCenterCallStateObserver {
    func callCenterDidChange(
        callState: CallState,
        conversation: ZMConversation,
        caller: UserType,
        timestamp: Date?,
        previousCallState: CallState?
    ) {
        updateVoiceChannelIfNeeded()
    }
}

// MARK: - WireCallCenterCallParticipantObserver

extension CallingContainerViewModel: WireCallCenterCallParticipantObserver {
    func callParticipantsDidChange(conversation: ZMConversation, participants: [CallParticipant]) {
        self.participants = voiceChannel.getParticipantsList()
    }
}

// MARK: - VoiceChannel participants helper

extension VoiceChannel {
    func getParticipantsList() -> CallParticipantsList {
        let sorted = participants(
            ofKind: .all,
            activeSpeakersLimit: CallInfoConfiguration.maxActiveSpeakers
        )
        return sorted.map {
            CallParticipantsListCellConfiguration.callParticipant(
                user: HashBox(value: $0.user),
                callParticipantState: $0.state,
                activeSpeakerState: $0.activeSpeakerState
            )
        }
    }
}
