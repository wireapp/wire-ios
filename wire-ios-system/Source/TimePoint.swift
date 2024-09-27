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

/// Records the passage of time since its creation. It also stores the callstack at creation time.
@objc(ZMSTimePoint) @objcMembers
public final class TimePoint: NSObject {
    // MARK: Lifecycle

    /// Creates a time point and records the callstack
    public convenience init(interval: TimeInterval) {
        self.init(interval: interval, label: "")
    }

    /// Creates a time point and records the callstack with a label used to identify the timepoint
    public init(interval: TimeInterval, label: String) {
        self.warnInterval = interval
        self.label = label
        self.timePoint = .now
    }

    // MARK: Public

    /// Time since creation
    public var elapsedTime: TimeInterval {
        -timePoint.timeIntervalSinceNow
    }

    /// Resets the creation time, but not the callstack
    public func resetTime() {
        timePoint = .now
    }

    /// Returns true if the current elapsed time was greater than the interval
    @discardableResult
    public func warnIfLongerThanInterval() -> Bool {
        guard elapsedTime > warnInterval else {
            return false
        }
        WireLogger.timePoint.warn("Time point (\(label)) warning threshold: \(elapsedTime) seconds elapsed")
        return true
    }

    // MARK: Internal

    /// If not zero, it will call @c warnIfLongerThanInteval with this value on dealloc
    let warnInterval: TimeInterval

    /// The label associated with this timepoint
    let label: String

    private(set) var timePoint: Date

    // MARK: Private

    private static var isTimePointEnabled: Bool {
        let timePointsCallStack = ProcessInfo.processInfo.environment["ZM_TIMEPOINTS_CALLSTACK"] as? NSString
        return timePointsCallStack?.boolValue ?? false
    }

    private let callstack = [String]()
}
