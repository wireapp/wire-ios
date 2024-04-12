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

extension Date {

    /// Initialze the date from the given transport string.

    init?(transportString: String) {
        if let date = ISO8601DateFormatter.default.date(from: transportString) {
            self = date
        } else if let date = ISO8601DateFormatter.withoutFractionalSeconds.date(from: transportString) {
            self = date
        } else {
            return nil
        }
    }

    /// Compute the string for transport to the server.

    func transportString() -> String {
        ISO8601DateFormatter.default.string(from: self)
    }

}
