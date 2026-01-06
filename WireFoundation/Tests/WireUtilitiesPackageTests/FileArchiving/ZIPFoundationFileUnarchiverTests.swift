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

struct ZIPFoundationFileUnarchiverTests {

    @Test
    func extractASingleRootFile() async throws {
        // Given
        let fileManager = FileManager.default
        let sut = ZIPFoundationFileUnarchiver()
        let archive = try #require(Bundle.module.url(forResource: "single-file", withExtension: "zip"))
        let temporaryDirectory = try fileManager.temporaryDirectory(appropriateFor: archive)
        defer { try? fileManager.removeItem(at: temporaryDirectory) }
        let expectedFile = temporaryDirectory.appending(path: "A.txt", directoryHint: .notDirectory)

        // When
        try sut.unzipFile(at: archive, to: temporaryDirectory)

        // Then
        #expect(fileManager.fileExists(atPath: expectedFile.path()))
        let content = try String(contentsOf: expectedFile)
        #expect(content == "-A-\n")
    }

    @Test
    func extractSingleFileInDirectory() async throws {
        // Given
        let fileManager = FileManager.default
        let sut = ZIPFoundationFileUnarchiver()
        let archive = try #require(Bundle.module.url(forResource: "single-file-in-directory", withExtension: "zip"))
        let temporaryDirectory = try fileManager.temporaryDirectory(appropriateFor: archive)
        defer { try? fileManager.removeItem(at: temporaryDirectory) }
        let expectedFile = temporaryDirectory
            .appending(path: "B", directoryHint: .isDirectory)
            .appending(path: "B.txt", directoryHint: .notDirectory)

        // When
        try sut.unzipFile(at: archive, to: temporaryDirectory)

        // Then
        #expect(fileManager.fileExists(atPath: expectedFile.path()))
        let content = try String(contentsOf: expectedFile)
        #expect(content == "-B-\n")
    }

    @Test
    func failForInvalidSourceUrls() async throws {
        // Given
        let fileManager = FileManager.default
        let sut = ZIPFoundationFileUnarchiver()
        let temporaryDirectory = try fileManager.temporaryDirectory()
        defer { try? fileManager.removeItem(at: temporaryDirectory) }
        let invalidURLs = [
            URL(string: "https://wire.com/file.zip")!,
            URL(filePath: "/path/to/non-existing/file.zip", directoryHint: .notDirectory),
            URL(filePath: "/", directoryHint: .isDirectory)
        ]

        // When & Then
        for invalidURL in invalidURLs {
            #expect(throws: (any Error).self) {
                try sut.unzipFile(at: invalidURL, to: temporaryDirectory)
            }
        }
    }

    @Test
    func failForInvalidDestinationUrls() async throws {
        // Given
        let fileManager = FileManager.default
        let sut = ZIPFoundationFileUnarchiver()
        let archive = try #require(Bundle.module.url(forResource: "single-file", withExtension: "zip"))
        let temporaryDirectory = try fileManager.temporaryDirectory()
        defer { try? fileManager.removeItem(at: temporaryDirectory) }
        let existingFile = temporaryDirectory.appending(path: "existing-file.zip", directoryHint: .notDirectory)
        try fileManager.copyItem(at: archive, to: existingFile)
        let invalidURLs = [
            URL(string: "https://wire.com/file.zip")!,
            URL(filePath: "/path/to/non-writable/directory", directoryHint: .isDirectory),
            existingFile
        ]

        // When & Then
        for invalidURL in invalidURLs {
            #expect(throws: (any Error).self) {
                try sut.unzipFile(at: archive, to: invalidURL)
            }
        }
    }

}
