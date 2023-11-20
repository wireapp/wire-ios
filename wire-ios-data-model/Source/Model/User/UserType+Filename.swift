//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

public extension UserType {
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-hh.mm.ss"
        return formatter
    }

    /// return a file name with length <= 255 - 4(reserve for extension) - 37(reserve for WireDataModel UUID prefix for meta) characters
    ///
    /// - Returns: a string <= 214 characters
    func filename(suffix: String? = nil) -> String {
        let dateString = "-" + dateFormatter.string(from: Date())
        let normalizedFilename = name!.normalizedFilename

        var numReservedChar = dateString.count

        if let suffixUnwrapped = suffix {
            numReservedChar += suffixUnwrapped.count
        }

        let trimmedFilename = normalizedFilename.trimmedFilename(numReservedChar: numReservedChar)

        if let suffixUnwrapped = suffix {
            return "\(trimmedFilename)\(dateString)\(suffixUnwrapped)"
        }
        else {
            return "\(trimmedFilename)\(dateString)"
        }
    }
}
