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

extension ISO8601DateFormatter {

    /// ISO8601 date formatter with internet date time and fractional seconds.

    static let `default` = {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return dateFormatter
    }()

    /// ISO8601 date formatter with internet date time but no fractional seconds.
    ///
    /// Due to a bug in the backend timestamps without fractional seconds are received.
    /// /// After the bug is fixed, this date formatter can be removed.
    /// See [WPB-6529](https://wearezeta.atlassian.net/browse/WPB-6529).

    static let withoutFractionalSeconds = {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime]
        return dateFormatter
    }()

}
