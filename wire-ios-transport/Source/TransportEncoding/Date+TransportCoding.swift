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

/// ISO8601 (.withInternetDateTime, .withFractionalSeconds)
private let iso8601DateWithFractionalSecondsFormatter = {
    let dateFormatter = ISO8601DateFormatter()
    dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return dateFormatter
}()

/// Covers the cases where no fractional seconds are provided.
/// Due to a bug in the backend timestamps without fractional seconds are received.
/// [WPB-6529](https://wearezeta.atlassian.net/browse/WPB-6529)
/// After the bug is fixed, this date formatter can be removed.
private let iso8601DateFormatter = {
    let dateFormatter = ISO8601DateFormatter()
    dateFormatter.formatOptions = [.withInternetDateTime]
    return dateFormatter
}()

// MARK: - Date + TransportCoding

extension Date: TransportCoding {
    public func transportString() -> String {
        iso8601DateWithFractionalSecondsFormatter.string(from: self)
    }

    public init?(transportString: String) {
        if let date = iso8601DateWithFractionalSecondsFormatter.date(from: transportString) {
            self = date
        } else if let date = iso8601DateFormatter.date(from: transportString) {
            self = date
        } else {
            return nil
        }
    }
}

extension NSDate {
    @objc(transportString) public var transportString: String {
        (self as Date).transportString()
    }

    @objc(dateWithTransportString:)
    public static func date(transportString: String) -> NSDate? {
        Date(transportString: transportString) as NSDate?
    }
}
