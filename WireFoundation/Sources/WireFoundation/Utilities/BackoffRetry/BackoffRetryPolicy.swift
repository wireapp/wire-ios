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

public struct BackoffRetryPolicy: Sendable {

    /// Max number of attempts
    public let maxRetries: Int

    /// The base time used in the backoff calculation
    public let baseTime: TimeInterval

    /// The maximum amount of time in seconds to wait before the next attempt
    public let maxTime: TimeInterval

    /// When calculating backoff time, the exponent is the number of attempts multiplied by
    /// this value. Decrease this value to shorten the backoff time.
    public let exponentMultiplier: Double

    /// Whether to introduce randomness into the backoff
    public let jitter: Bool

    public init(
        maxRetries: Int = 3,
        baseTime: TimeInterval = 1.0,
        maxTime: TimeInterval = 30,
        exponentMultiplier: Double = 2.0,
        jitter: Bool = false
    ) {
        self.maxRetries = maxRetries
        self.baseTime = baseTime
        self.maxTime = maxTime
        self.exponentMultiplier = exponentMultiplier
        self.jitter = jitter
    }
}
