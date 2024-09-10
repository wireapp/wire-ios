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

enum MediaState: Equatable {
    struct SpeakerState: Equatable {
        let isEnabled: Bool
        let canBeToggled: Bool
    }

    case sendingVideo(speakerState: SpeakerState), notSendingVideo(speakerState: SpeakerState)

    var isSendingVideo: Bool {
        guard case .sendingVideo = self else { return false }
        return true
    }

    var isSpeakerEnabled: Bool {
        switch self {
        case let .notSendingVideo(state):
            return state.isEnabled
        case let .sendingVideo(state):
            return state.isEnabled
        }
    }

    var canSpeakerBeToggled: Bool {
        switch self {
        case let .notSendingVideo(state):
            return state.canBeToggled
        case let .sendingVideo(state):
            return state.canBeToggled
        }
    }
}
