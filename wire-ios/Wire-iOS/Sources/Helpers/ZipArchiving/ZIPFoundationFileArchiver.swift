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

import Foundation
import WireFoundation
import ZIPFoundation

struct ZIPFoundationFileArchiver: FileArchiverProtocol {

    func zipResources(
        at resourceURLs: [URL],
        into destinationURL: URL
    ) throws {

        // We need to pass a directory URL to ZIPFoundation. Therefore we first copy the target files into a separate,
        // temporary directory representing the future zip content.

        let fileManager = FileManager.default
        let sourceURL = destinationURL
            .deletingLastPathComponent()
            .appending(path: destinationURL.deletingPathExtension().lastPathComponent, directoryHint: .isDirectory)
        try fileManager.createDirectory(at: sourceURL, withIntermediateDirectories: false)
        for resourceURL in resourceURLs {
            try fileManager.copyItem(
                at: resourceURL,
                to: sourceURL.appending(path: resourceURL.lastPathComponent, directoryHint: .notDirectory)
            )
        }
        defer {
            try? fileManager.removeItem(at: sourceURL)
        }

        try fileManager.zipItem(
            at: sourceURL,
            to: destinationURL,
            shouldKeepParent: false,
            compressionMethod: .deflate,
            progress: .none
        )

    }

}
