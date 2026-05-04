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
import Testing

@testable import WireUtilitiesPackage

struct ZIPFoundationFileArchiverTests {

    @Test
    func createAnArchiveFromASingleFile() async throws {
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

    @Test
    func createAnArchiveFromADirectory() async throws {
        // Given
        let fileManager = FileManager.default
        let temporaryDirectory = try fileManager.temporaryDirectory(create: true)
        defer { try? fileManager.removeItem(at: temporaryDirectory) }
        let directoryURL = temporaryDirectory.appending(path: "C", directoryHint: .isDirectory)
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: false)
        let fileURL = directoryURL.appending(path: "C.txt", directoryHint: .notDirectory)
        let archiveURL = temporaryDirectory.appending(path: "C.zip", directoryHint: .notDirectory)
        try "-C-".write(to: fileURL, atomically: true, encoding: .utf8)
        let sut = ZIPFoundationFileArchiver()

        // When
        try sut.zipResources(at: [directoryURL], into: archiveURL)

        // Then
        try fileManager.removeItem(at: directoryURL)
        try ZIPFoundationFileUnarchiver().unzipFile(at: archiveURL, to: temporaryDirectory)
        let content = try String(contentsOf: fileURL)
        #expect(content == "-C-")
    }

    @Test
    func createAnArchiveFromInvalidSourceFiles() async throws {
        // Given
        let fileManager = FileManager.default
        let temporaryDirectory = try fileManager.temporaryDirectory(create: true)
        defer { try? fileManager.removeItem(at: temporaryDirectory) }
        let archiveURL = temporaryDirectory.appending(path: "C.zip", directoryHint: .notDirectory)
        let invalidURLs = [
            URL(string: "https://wire.com/file.zip")!,
            URL(filePath: "/path/to/non-writable/directory", directoryHint: .isDirectory)
        ]
        let sut = ZIPFoundationFileArchiver()

        // When & Then
        for invalidURL in invalidURLs {
            #expect(throws: (any Error).self) {
                try sut.zipResources(at: [invalidURL], into: archiveURL)
            }
        }
    }

    @Test
    func createAnArchiveAtAnInvalidDestinationUrl() async throws {
        // Given
        let fileManager = FileManager.default
        let temporaryDirectory = try fileManager.temporaryDirectory(create: true)
        defer { try? fileManager.removeItem(at: temporaryDirectory) }
        let fileURL = temporaryDirectory.appending(path: "C.txt", directoryHint: .notDirectory)
        try "-C-".write(to: fileURL, atomically: true, encoding: .utf8)
        let invalidURLs = [
            URL(string: "https://wire.com/file.zip")!,
            URL(filePath: "/path/to/non-writable/directory", directoryHint: .isDirectory),
            temporaryDirectory, // an existing directory
            fileURL // existing file
        ]
        let sut = ZIPFoundationFileArchiver()

        // When & Then
        for invalidURL in invalidURLs {
            #expect(throws: (any Error).self) {
                try sut.zipResources(at: [fileURL], into: invalidURL)
            }
        }
    }

}
