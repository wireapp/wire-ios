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

import UIKit
import WireCommonComponents
import WireDesign
import WireUtilities

enum CallActionIconType: IconLabelButtonInput {
    case microphone
    case camera
    case speaker
    case flipCamera
    case endCall
    case pickUp

    // MARK: Internal

    var label: String {
        typealias Voice = L10n.Localizable.Voice

        switch self {
        case .microphone: return Voice.MuteButton.title
        case .camera: return Voice.VideoButton.title
        case .speaker: return Voice.SpeakerButton.title
        case .flipCamera: return Voice.FlipCameraButton.title
        case .endCall:  return Voice.HangUpButton.title
        case .pickUp: return Voice.PickUpButton.title
        }
    }

    var accessibilityIdentifier: String {
        switch self {
        case .microphone: "CallMuteButton"
        case .camera: "CallVideoButton"
        case .speaker: "CallSpeakerButton"
        case .flipCamera: "CallFlipCameraButton"
        case .endCall: "EndCallButton"
        case .pickUp: "PickUpButton"
        }
    }

    func icon(forState state: UIControl.State) -> StyleKitIcon {
        switch state {
        case .selected: selectedIcon
        default: normalIcon
        }
    }

    // MARK: Private

    private var normalIcon: StyleKitIcon {
        switch self {
        case .microphone: .microphoneOff
        case .camera: .cameraOff
        case .speaker: .speakerOff
        case .flipCamera: .flipCamera
        case .endCall: .endCall
        case .pickUp: .endCall
        }
    }

    private var selectedIcon: StyleKitIcon {
        switch self {
        case .microphone: .microphone
        case .camera: .camera
        case .speaker: .speaker
        case .flipCamera: .flipCamera
        case .endCall: .endCall
        case .pickUp: .endCall
        }
    }
}
