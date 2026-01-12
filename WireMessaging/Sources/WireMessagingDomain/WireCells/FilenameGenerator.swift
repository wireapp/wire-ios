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

package import Foundation
import UniformTypeIdentifiers

/// Generates filenames based on the current `Date` & a files `UTType`, ensuring uniqueness for the same date.
package actor FilenameGenerator {

    private struct Filename: Hashable {
        let prefix: String
        let dateComponent: String
        let fileExtension: String?
    }

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    private var previouslyGeneratedFilenames: [Filename: Int] = [:]
    private let date: () -> Date

    package init(date: @escaping () -> Date = { Date() }) {
        self.date = date
    }

    /// Generates a filename such as "IMG_20231005_153045_1.jpg" or "FILE_20231005_153045.pdf".
    func generateFilename(type: UTType) -> String {
        let filename = Filename(
            prefix: type.conforms(to: .image) ? "IMG" : "FILE",
            dateComponent: dateFormatter.string(from: date()),
            fileExtension: type.preferredFilenameExtension
        )

        let count = (previouslyGeneratedFilenames[filename] ?? 0) + 1
        previouslyGeneratedFilenames[filename] = count

        var result = "\(filename.prefix)_\(filename.dateComponent)"
        if count > 1 {
            result += "_\(count - 1)"
        }

        if let fileExtension = filename.fileExtension {
            result += ".\(fileExtension)"
        }

        return result
    }
}
