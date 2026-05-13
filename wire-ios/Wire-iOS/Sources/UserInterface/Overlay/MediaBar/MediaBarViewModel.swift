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

struct MediaBarViewModel {

    enum PlayPauseIcon: Equatable {
        case play
        case pause
    }

    struct DisplayState: Equatable {
        let playPauseIcon: PlayPauseIcon
        let playPauseAccessibilityIdentifier: String
    }

    enum Action: Equatable {
        case play
        case pause
        case stop
    }

    func displayState(isPlaying: Bool) -> DisplayState {
        if isPlaying {
            return DisplayState(
                playPauseIcon: .pause,
                playPauseAccessibilityIdentifier: "mediaBarPauseButton"
            )
        } else {
            return DisplayState(
                playPauseIcon: .play,
                playPauseAccessibilityIdentifier: "mediaBarPlayButton"
            )
        }
    }

    func playPauseAction(isPlaying: Bool) -> Action {
        isPlaying ? .pause : .play
    }

    func stopAction() -> Action {
        .stop
    }
}
