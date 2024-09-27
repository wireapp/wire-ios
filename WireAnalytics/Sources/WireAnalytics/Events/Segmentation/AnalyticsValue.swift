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

/// A value that can be tracked.

public protocol AnalyticsValue {

    /// A representation suitable for tracking.

    var analyticsValue: String { get }

}

extension Bool: AnalyticsValue {

    public var analyticsValue: String {
        self ? "True" : "False"
    }

}


extension UInt: AnalyticsValue {

    public var analyticsValue: String {
        String(logRound())
    }

    /// Rounds the integer value logarithmically to protect the privacy of BI data.
    ///
    /// The `logRound` method rounds numeric values into buckets of increasing size.
    /// This logarithmic rounding means that smaller numbers are only slightly rounded,
    /// whereas larger numbers are rounded more significantly. This approach helps to
    /// protect privacy by reducing the precision of the values in a controlled manner.
    ///
    /// - Returns: A rounded integer value based on the base-2 logarithm of the original value.

    func logRound() -> UInt {
        UInt(log2(Double(self)).rounded())
    }

}
