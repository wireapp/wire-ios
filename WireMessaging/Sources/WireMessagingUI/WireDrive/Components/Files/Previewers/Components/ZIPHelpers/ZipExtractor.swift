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

import Foundation
import WireLogging
import ZIPFoundation

enum ZipExtractor {
    static func extractEntry(
        _ path: String,
        from archiveURL: URL
    ) -> URL? {
        do {
            let archive = try Archive(
                url: archiveURL,
                accessMode: .read
            )

            guard let entry =
                archive[path] else {
                throw CocoaError(.fileNoSuchFile)
            }

            let destination =
                FileManager.default.temporaryDirectory.appendingPathComponent(
                    UUID().uuidString
                ).appendingPathExtension(
                    URL(filePath: path).pathExtension
                )

            _ = try archive.extract(
                entry,
                to: destination
            )

            return destination
        } catch {
            WireLogger.wireDrive.error(
                "Unabled to extract entry from archived file, archiveURL: \(archiveURL), entry: \(path)"
            )

            return nil
        }
    }
}
