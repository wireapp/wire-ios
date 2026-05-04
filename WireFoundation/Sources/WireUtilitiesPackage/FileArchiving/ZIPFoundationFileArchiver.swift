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

import ZIPFoundation

public struct ZIPFoundationFileArchiver: FileArchiverProtocol {

    public init() {}

    public func zipResources(
        at resourceURLs: [URL],
        into destinationURL: URL
    ) throws {

        // We need to pass a directory URL to ZIPFoundation. Therefore we first copy the target files into a separate,
        // temporary directory representing the content of the zip file.

        let fileManager = FileManager.default
        let tmpDestination = try fileManager.url(
            for: .itemReplacementDirectory,
            in: .userDomainMask,
            appropriateFor: destinationURL,
            create: true
        )
        defer { try? fileManager.removeItem(at: tmpDestination) }

        for resourceURL in resourceURLs {
            try fileManager.copyItem(
                at: resourceURL,
                to: tmpDestination.appending(path: resourceURL.lastPathComponent, directoryHint: .notDirectory)
            )
        }

        try fileManager.zipItem(
            at: tmpDestination,
            to: destinationURL,
            shouldKeepParent: false,
            compressionMethod: .deflate
        )

    }

}
