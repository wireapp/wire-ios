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

    func zipResources(at resourceURLs: [URL], into destinationURL: URL) throws {
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true)
        for resourceURL in resourceURLs {
            try fileManager.copyItem(
                at: resourceURL,
                to: destinationURL.appending(path: resourceURL.lastPathComponent, directoryHint: .notDirectory)
            )
        }
        try fileManager.zipItem(at: destinationURL, to: destinationURL.appendingPathExtension("tmp"))
        try fileManager.removeItem(at: destinationURL)
        try fileManager.moveItem(at: destinationURL.appendingPathExtension("tmp"), to: destinationURL)
    }

}
