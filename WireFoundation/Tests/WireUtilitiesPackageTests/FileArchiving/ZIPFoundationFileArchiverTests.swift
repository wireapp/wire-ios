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
import Testing

@testable import WireUtilitiesPackage

struct ZIPFoundationFileArchiverTests {

    @Test func `test creating an archive from a single file`() async throws {
        // Given
        let fileManager = FileManager.default
        let temporaryDirectory = try fileManager.temporaryDirectory(create: true)
        defer { try? fileManager.removeItem(at: temporaryDirectory) }
        let fileURL = temporaryDirectory.appending(path: "C.txt", directoryHint: .notDirectory)
        let archiveURL = temporaryDirectory.appending(path: "C.zip", directoryHint: .notDirectory)
        try "-C-".write(to: fileURL, atomically: true, encoding: .utf8)
        let sut = ZIPFoundationFileArchiver()

        // When
        try sut.zipResources(at: [fileURL], into: archiveURL)

        // Then
        let unzippedDirectory = temporaryDirectory.appending(path: "C", directoryHint: .isDirectory)
        try ZIPFoundationFileUnarchiver().unzipFile(at: archiveURL, to: unzippedDirectory)
        let content = try String(contentsOf: unzippedDirectory.appending(path: "C.txt", directoryHint: .notDirectory))
        #expect(content == "-C-")
    }

    // TODO: test cleanup, no permission, invalid url, unzipping, non-existent source files

}

// TODO: test WireBackup manually
