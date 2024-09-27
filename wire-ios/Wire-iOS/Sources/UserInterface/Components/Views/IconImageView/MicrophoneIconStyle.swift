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
import WireCommonComponents
import WireDesign
import WireSyncEngine

// MARK: - MicrophoneIconStyle

enum MicrophoneIconStyle: String {
    case muted
    case unmuted
    case unmutedPulsing
    case hidden
}

// MARK: IconImageStyle

extension MicrophoneIconStyle: IconImageStyle {
    var icon: StyleKitIcon? {
        switch self {
        case .muted:
            .microphoneOff
        case .unmuted, .unmutedPulsing:
            .microphone
        case .hidden:
            .none
        }
    }

    var tintColor: UIColor? {
        switch self {
        case .unmutedPulsing:
            .accent()
        default:
            nil
        }
    }

    var accessibilityPrefix: String {
        "img.microphone"
    }

    var accessibilitySuffix: String {
        rawValue
    }

    var accessibilityLabel: String {
        typealias Calling = L10n.Accessibility.Calling

        switch self {
        case .unmuted, .unmutedPulsing:
            return Calling.MicrophoneOn.description
        case .muted, .hidden:
            return Calling.MicrophoneOff.description
        }
    }
}

// MARK: PulsingIconImageStyle

extension MicrophoneIconStyle: PulsingIconImageStyle {
    var shouldPulse: Bool { self == .unmutedPulsing }
}

extension MicrophoneIconStyle {
    init(state: MicrophoneState?, shouldPulse: Bool) {
        guard let state else {
            self = .muted
            return
        }
        switch state {
        case .unmuted where shouldPulse:
            self = .unmutedPulsing
        case .unmuted:
            self = .unmuted
        case .muted:
            self = .muted
        }
    }
}
