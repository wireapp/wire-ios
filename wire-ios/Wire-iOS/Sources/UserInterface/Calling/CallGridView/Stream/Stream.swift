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

import DifferenceKit
import Foundation
import WireSyncEngine

// MARK: - Stream

struct Stream: Equatable {
    let streamId: AVSClient
    let user: UserType?
    let callParticipantState: CallParticipantState
    let activeSpeakerState: ActiveSpeakerState
    let isPaused: Bool
}

// MARK: Differentiable

extension Stream: Differentiable {
    var differenceIdentifier: AVSClient {
        streamId
    }

    var microphoneState: MicrophoneState? {
        guard case let .connected(_, state) = callParticipantState else {
            return nil
        }
        return state
    }

    var videoState: VideoState? {
        guard case let .connected(state, _) = callParticipantState else {
            return nil
        }
        return state
    }
}

extension Stream {
    static func == (lhs: Stream, rhs: Stream) -> Bool {
        lhs.streamId == rhs.streamId
            && lhs.callParticipantState == rhs.callParticipantState
            && lhs.activeSpeakerState == rhs.activeSpeakerState
    }
}
