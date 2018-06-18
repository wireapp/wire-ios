//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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


public enum ZMConversationMessageDestructionTimeout : RawRepresentable, Hashable {

    case none
    case tenSeconds
    case fiveMinutes
    case oneHour
    case oneDay
    case oneWeek
    case fourWeeks

    case custom(TimeInterval)

    public init(rawValue: TimeInterval) {
        switch rawValue {
        case 0: self = .none
        case 10: self = .tenSeconds
        case 300: self = .fiveMinutes
        case 3600: self = .oneHour
        case 86400: self = .oneDay
        case 604800: self = .oneWeek
        case 2419200: self = .fourWeeks
        default: self = .custom(rawValue)
        }
    }

    public var rawValue: TimeInterval {
        switch self {
        case .none: return 0
        case .tenSeconds: return 10
        case .fiveMinutes: return 300
        case .oneHour: return 3600
        case .oneDay: return 86400
        case .oneWeek: return 604800
        case .fourWeeks: return 2419200
        case .custom(let duration): return duration
        }
    }

}

public extension ZMConversationMessageDestructionTimeout {

    static var all: [ZMConversationMessageDestructionTimeout] {
        return [
            .none,
            .tenSeconds,
            .fiveMinutes,
            .oneHour,
            .oneDay,
            .oneWeek,
            .fourWeeks
        ]
    }
}

public extension ZMConversationMessageDestructionTimeout {

    public var isKnownTimeout: Bool {
        if case .custom = self {
            return false
        }
        return true
    }

}

public extension ZMConversation {

    /// Sets messageDestructionTimeout
    /// @param timeout: The timeout after which an appended message should "self-destruct"
    public func updateMessageDestructionTimeout(timeout : ZMConversationMessageDestructionTimeout) {
        messageDestructionTimeout = timeout.rawValue
    }

    @objc public var destructionEnabled: Bool {
        return destructionTimeout != .none
    }

    public var destructionTimeout: ZMConversationMessageDestructionTimeout {
        return ZMConversationMessageDestructionTimeout(rawValue: messageDestructionTimeout)
    }
}

