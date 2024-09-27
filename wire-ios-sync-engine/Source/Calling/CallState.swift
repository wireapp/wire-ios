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

private let zmLog = ZMSLog(tag: "calling")

// MARK: - CallParticipant

/// A participant in the call.

public struct CallParticipant: Hashable {
    public let user: UserType
    public let clientId: String
    public let userId: AVSIdentifier
    public let state: CallParticipantState
    public let activeSpeakerState: ActiveSpeakerState

    /// convenience init method for ZMUser
    /// - Parameters:
    ///   - user: the call participant ZMUser
    ///   - clientId: the call participant's client
    ///   - state: the call participant's state
    public init(
        user: ZMUser,
        clientId: String,
        state: CallParticipantState,
        activeSpeakerState: ActiveSpeakerState
    ) {
        self.user = user
        self.clientId = clientId
        self.userId = user.avsIdentifier
        self.state = state
        self.activeSpeakerState = activeSpeakerState
    }

    /// Init with separated user and user id to allow CallParticipant to be Hashable even though user is not Hashable
    /// - Parameters:
    ///   - user: the call participant user
    ///   - userId: the call participant user's id
    ///   - clientId: the call participant's client
    ///   - state: the call participant's state
    public init(
        user: UserType,
        userId: AVSIdentifier,
        clientId: String,
        state: CallParticipantState,
        activeSpeakerState: ActiveSpeakerState
    ) {
        self.user = user
        self.clientId = clientId
        self.userId = userId
        self.state = state
        self.activeSpeakerState = activeSpeakerState
    }

    init?(member: AVSCallMember, activeSpeakerState: ActiveSpeakerState = .inactive, context: NSManagedObjectContext) {
        let userId = member.client.avsIdentifier

        guard let user = ZMUser.fetch(with: userId.identifier, domain: userId.domain, in: context) else {
            return nil
        }

        self.init(
            user: user,
            userId: userId,
            clientId: member.client.clientId,
            state: member.callParticipantState,
            activeSpeakerState: activeSpeakerState
        )
    }

    // MARK: - Hashable

    public static func == (lhs: CallParticipant, rhs: CallParticipant) -> Bool {
        lhs.userId == rhs.userId &&
            lhs.clientId == rhs.clientId &&
            lhs.state == rhs.state
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(userId)
        hasher.combine(clientId)
    }
}

// MARK: - CallParticipantState

/// The state of a participant in a call.

public enum CallParticipantState: Equatable, Hashable {
    /// Participant is not in the call
    case unconnected
    /// A network problem occured but the call may still connect
    case unconnectedButMayConnect
    /// Participant is in the process of connecting to the call
    case connecting
    /// Participant is connected to the call and audio is flowing
    case connected(videoState: VideoState, microphoneState: MicrophoneState)
}

// MARK: - AudioState

/// The audio state of a participant in a call.

public enum AudioState: Int32, Codable {
    /// Audio is in the process of connecting.
    case connecting = 0
    /// Audio has been established and is flowing.
    case established = 1
    /// No relay candidate, though audio may still connect.
    case networkProblem = 2
}

// MARK: - VideoState

/// The state of video in the call.

public enum VideoState: Int32, Codable {
    /// Sender is not sending video
    case stopped = 0
    /// Sender is sending video
    case started = 1
    /// Sender is sending video but currently has a bad connection
    case badConnection = 2
    /// Sender has paused the video
    case paused = 3
    /// Sender is sending a video of his/her desktop
    case screenSharing = 4
}

// MARK: - MicrophoneState

/// The state of microphone in the call

public enum MicrophoneState: Int32, Codable {
    /// Sender is unmuted
    case unmuted = 0
    /// Sender is muted
    case muted = 1
}

// MARK: - ActiveSpeakerState

/// The speaking activity state of a participant in the call.

public enum ActiveSpeakerState: Hashable {
    /// Participant is an active speaker
    case active(audioLevelNow: Int)
    /// Participant is not an active speaker
    case inactive
}

// MARK: - CallState

/// The current state of a call.

public enum CallState: Equatable {
    /// There's no call
    case none
    /// Outgoing call is pending
    case outgoing(degraded: Bool)
    /// Incoming call is pending
    case incoming(video: Bool, shouldRing: Bool, degraded: Bool)
    /// Call is answered
    case answered(degraded: Bool)
    /// Call is established (data is flowing)
    case establishedDataChannel
    /// Call is established (media is flowing)
    case established
    /// Call is over and audio/video is guranteed to be stopped
    case mediaStopped
    /// Call in process of being terminated
    case terminating(reason: CallClosedReason)
    /// Unknown call state
    case unknown

    /// Logs the current state to the calling logs.

    func logState() {
        switch self {
        case let .answered(degraded: degraded):
            zmLog.debug("answered call, degraded: \(degraded)")
        case let .incoming(video: isVideo, shouldRing: shouldRing, degraded: degraded):
            zmLog.debug("incoming call, isVideo: \(isVideo), shouldRing: \(shouldRing), degraded: \(degraded)")
        case .establishedDataChannel:
            zmLog.debug("established data channel")
        case .established:
            zmLog.debug("established call")
        case let .outgoing(degraded: degraded):
            zmLog.debug("outgoing call, , degraded: \(degraded)")
        case let .terminating(reason: reason):
            zmLog.debug("terminating call reason: \(reason)")
        case .mediaStopped:
            zmLog.debug("media stopped")
        case .none:
            zmLog.debug("no call")
        case .unknown:
            zmLog.debug("unknown call state")
        }
    }

    /// Updates the state of the call when the security level changes.
    /// - parameter isConversationDegraded: Has conversation been degraded?
    /// - returns: The current status, updated with the appropriate degradation information.

    func update(isConversationDegraded: Bool) -> CallState {
        switch self {
        case .incoming(video: let video, shouldRing: let shouldRing, degraded: _):
            .incoming(video: video, shouldRing: shouldRing, degraded: isConversationDegraded)
        case .outgoing:
            .outgoing(degraded: isConversationDegraded)
        case .answered:
            .answered(degraded: isConversationDegraded)
        default:
            self
        }
    }
}
