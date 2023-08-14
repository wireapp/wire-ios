//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

/// Represents the sound for types of notifications.
public enum NotificationSound {

    /// Storage of the user's preferred notification sounds.

    public static var storage: UserDefaults = .standard

    case call, ping, newMessage

    /// The name of the song.
    public var name: String {
        return defaultFileName
    }

    // MARK: - Utilities

    private var defaultFileName: String {
        switch self {
        case .call: return "ringing_from_them_long.caf"
        case .ping: return "ping_from_them.caf"
        case .newMessage: return "default"
        }
    }

    // Unused - leaving this here in case we need to support custom sounds again in the future.
    private var preferenceKey: String {
        switch self {
        case .call: return "ZMCallSoundName"
        case .ping: return "ZMPingSoundName"
        case .newMessage: return "ZMMessageSoundName"
        }
    }
}
