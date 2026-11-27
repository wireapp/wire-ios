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

import Foundation

public enum MessageNotificationSound: String, CaseIterable {
    case wire
    case wireLegacy

    public static let preferenceKey = "messageNotificationSound"

    public var fileName: String {
        switch self {
        case .wire: "new_message.caf"
        case .wireLegacy: "new_message_legacy.caf"
        }
    }

    public static func selected(in defaults: UserDefaults) -> MessageNotificationSound {
        defaults.string(forKey: preferenceKey).flatMap(Self.init(rawValue:)) ?? .wire
    }

    public func save(in defaults: UserDefaults) {
        defaults.set(rawValue, forKey: Self.preferenceKey)
    }
}
