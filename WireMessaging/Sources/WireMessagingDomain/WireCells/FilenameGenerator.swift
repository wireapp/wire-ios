//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

package import Foundation
import UniformTypeIdentifiers

/// Generates filenames based on the current `Date` & a files `UTType`, ensuring uniqueness for the same date.
package actor FilenameGenerator {

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    private var existing: [String: Int] = [:]
    private let date: () -> Date

    package init(date: @escaping () -> Date = { Date() }) {
        self.date = date
    }

    /// Generates a filename such as "IMG_20231005_153045_1.jpg" or "FILE_20231005_153045.pdf".
    func generateFilename(type: UTType) -> String {
        var filename = ""

        // Prefix
        if type.conforms(to: .image) {
            filename += "IMG"
        } else {
            filename += "FILE"
        }

        // Date
        let dateComponent = dateFormatter.string(from: date())
        filename += "_\(dateComponent)"

        // Suffix in case of date collision
        let count = (existing[dateComponent] ?? 0) + 1
        existing[dateComponent] = count
        if count > 1 {
            filename += "_\(count - 1)"
        }

        // Extension
        if let fileExtension = type.preferredFilenameExtension {
            filename += ".\(fileExtension)"
        }

        return filename
    }
}
