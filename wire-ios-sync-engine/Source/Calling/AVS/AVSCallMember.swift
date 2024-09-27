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

import avs
import Foundation

// MARK: - AVSCallMember

/// An object that represents the member of an AVS call.

public struct AVSCallMember: Hashable {
    /// The client used in the call.
    public let client: AVSClient

    /// The state of the audio connection.
    public let audioState: AudioState

    /// The state of video connection.
    public let videoState: VideoState

    /// The state of microphone
    public let microphoneState: MicrophoneState

    // MARK: - Initialization

    /// Creates the call member from its values.
    /// - parameter client: The client used in the call.
    /// - parameter audioState: The state of the audio connection. Defaults to `.connecting`.
    /// - parameter videoState: The state of video connection. Defaults to `stopped`.
    /// - parameter microphoneState: The state of microphone. Defaults to `unmuted`.
    /// - parameter networkQuality: The quality of the network connection. Defaults to `.normal`.

    public init(
        client: AVSClient,
        audioState: AudioState = .connecting,
        videoState: VideoState = .stopped,
        microphoneState: MicrophoneState = .unmuted
    ) {
        self.client = client
        self.audioState = audioState
        self.videoState = videoState
        self.microphoneState = microphoneState
    }

    // MARK: - Properties

    /// The state of the participant.
    var callParticipantState: CallParticipantState {
        switch audioState {
        case .connecting:
            .connecting
        case .established:
            .connected(videoState: videoState, microphoneState: microphoneState)
        case .networkProblem:
            .unconnectedButMayConnect
        }
    }

    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(client)
    }

    public static func == (lhs: AVSCallMember, rhs: AVSCallMember) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
}

extension AVSCallMember {
    init(member: AVSParticipantsChange.Member) {
        self.client = AVSClient(member: member)
        self.audioState = member.aestab
        self.videoState = member.vrecv
        self.microphoneState = member.muted
    }
}

extension AVSClient {
    fileprivate init(member: AVSParticipantsChange.Member) {
        userId = member.userid
        clientId = member.clientid
    }
}
