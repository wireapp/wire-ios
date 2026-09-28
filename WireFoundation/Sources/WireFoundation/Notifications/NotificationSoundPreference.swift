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

public import Foundation

public enum NotificationSoundPreference: String, CaseIterable, Sendable {

    case systemDefault
    case wire

    public static let storageKey = "NotificationSoundPreference"
    public static let defaultValue = NotificationSoundPreference.wire

    public static func stored(in userDefaults: UserDefaults) -> NotificationSoundPreference {
        userDefaults.string(forKey: storageKey).flatMap(NotificationSoundPreference.init(rawValue:)) ?? defaultValue
    }

    public func store(in userDefaults: UserDefaults) {
        userDefaults.set(rawValue, forKey: Self.storageKey)
    }

    public var notificationSoundName: String {
        switch self {
        case .systemDefault:
            "default"
        case .wire:
            "new_message.caf"
        }
    }
}
