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

/// A type representing the possible timeout values.

public enum MessageDestructionTimeoutValue: RawRepresentable, Hashable {
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
        case .zero:
            self = .none

        case .tenSeconds:
            self = .tenSeconds

        case .fiveMinutes:
            self = .fiveMinutes

        case .oneHour:
            self = .oneHour

        case .oneDay:
            self = .oneDay

        case .oneWeek:
            self = .oneWeek

        case .fourWeeks:
            self = .fourWeeks

        default:
            self = .custom(rawValue)
        }
    }

    public var rawValue: TimeInterval {
        switch self {
        case .none:
            .zero

        case .tenSeconds:
            .tenSeconds

        case .fiveMinutes:
            .fiveMinutes

        case .oneHour:
            .oneHour

        case .oneDay:
            .oneDay

        case .oneWeek:
            .oneWeek

        case .fourWeeks:
            .fourWeeks

        case let .custom(duration):
            duration
        }
    }
}

extension MessageDestructionTimeoutValue {
    public static var all: [Self] {
        [
            .none,
            .tenSeconds,
            .fiveMinutes,
            .oneHour,
            .oneDay,
            .oneWeek,
            .fourWeeks,
        ]
    }

    public var displayString: String? {
        guard self != .none else { return NSLocalizedString("input.ephemeral.timeout.none", comment: "") }
        return longStyleFormatter.string(from: TimeInterval(rawValue))
    }

    public var shortDisplayString: String? {
        if isSeconds {
            return String(Int(rawValue))
        }

        if isMinutes {
            return String(Int(rawValue / .oneMinute))
        }

        if isHours {
            return String(Int(rawValue / .oneHour))
        }

        if isDays {
            return String(Int(rawValue / .oneDay))
        }

        if isWeeks {
            return String(Int(rawValue / .oneWeek))
        }

        if isYears {
            return String(Int(rawValue / .oneYearFromNow))
        }

        return nil
    }

    public var isSeconds: Bool {
        .zero ..< .oneMinute ~= rawValue
    }

    public var isMinutes: Bool {
        .oneMinute ..< .oneHour ~= rawValue
    }

    public var isHours: Bool {
        .oneHour ..< .oneDay ~= rawValue
    }

    public var isDays: Bool {
        .oneDay ..< .oneWeek ~= rawValue
    }

    public var isWeeks: Bool {
        .oneWeek ..< .oneYearFromNow ~= rawValue
    }

    public var isYears: Bool {
        rawValue >= .oneYearFromNow
    }
}

private let longStyleFormatter: DateComponentsFormatter = {
    let formatter = DateComponentsFormatter()
    formatter.includesApproximationPhrase = false
    formatter.maximumUnitCount = 1
    formatter.unitsStyle = .full
    formatter.allowedUnits = [.year, .weekOfMonth, .day, .hour, .minute, .second]
    formatter.zeroFormattingBehavior = .dropAll
    return formatter
}()
