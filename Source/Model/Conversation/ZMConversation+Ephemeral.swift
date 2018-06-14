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


public enum ZMConversationMessageDestructionTimeout : TimeInterval {
    case none = 0
    case fiveSeconds = 5
    case fifteenSeconds = 15
    case thirtySeconds = 30
    case oneMinute = 60
    case fiveMinutes = 300
    case oneDay = 86400
}

public extension ZMConversationMessageDestructionTimeout {

    static var all: [ZMConversationMessageDestructionTimeout] {
        return [
            .none,
            .fiveSeconds,
            .fifteenSeconds,
            .thirtySeconds,
            .oneMinute,
            .fiveMinutes,
            .oneDay
        ]
    }
}

public extension ZMConversationMessageDestructionTimeout {

    public static func validTimeout(for timeout: TimeInterval) -> TimeInterval {
        return timeout.clamp(
            between: ZMConversationMessageDestructionTimeout.fiveSeconds.rawValue,
            and: ZMConversationMessageDestructionTimeout.oneDay.rawValue
        )
    }
}

fileprivate extension TimeInterval {
    func clamp(between lower: TimeInterval, and upper: TimeInterval) -> TimeInterval {
        return fmax(lower, fmin(upper, self))
    }
}

public extension ZMConversation {

    /// Sets messageDestructionTimeout
    /// @param timeout The timeout after which an appended message should "self-destruct"
    public func updateMessageDestructionTimeout(timeout : ZMConversationMessageDestructionTimeout) {
        messageDestructionTimeout = timeout.rawValue
    }

    @objc public var destructionEnabled: Bool {
        return destructionTimeout != .none
    }

    public var destructionTimeout: ZMConversationMessageDestructionTimeout {
        return ZMConversationMessageDestructionTimeout(rawValue: messageDestructionTimeout) ?? .none
    }

    @objc public var canSendEphemeral: Bool {
        return self.activeParticipants.count > 1
    }
}


