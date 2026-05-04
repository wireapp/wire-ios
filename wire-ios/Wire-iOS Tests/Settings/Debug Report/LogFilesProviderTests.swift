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
import XCTest
@testable import Wire

final class LogFilesProviderTests: XCTestCase {

    var provider: LogFilesProvider!

    override func setUp() {
        super.setUp()
        provider = LogFilesProvider()
    }

    func test_generateLogFilesZip_createsZipFile() throws {
        // GIVEN / WHEN
        let zipURL = try provider.generateLogFilesZip()

        // THEN
        XCTAssertTrue(FileManager.default.fileExists(atPath: zipURL.path))
    }

    func test_logsDirectoryIsCleanedBeforeArchiving() throws {
        // GIVEN
        let testDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("logs")
        try FileManager.default.createDirectory(at: testDirectory, withIntermediateDirectories: true)
        let dummyFile = testDirectory.appendingPathComponent("old.txt")
        FileManager.default.createFile(atPath: dummyFile.path, contents: Data("dummy".utf8))

        XCTAssertTrue(FileManager.default.fileExists(atPath: dummyFile.path))

        // WHEN
        _ = try provider.generateLogFilesZip()

        // THEN
        let contents = try FileManager.default.contentsOfDirectory(at: testDirectory, includingPropertiesForKeys: nil)
        XCTAssertFalse(contents.contains(where: { $0.lastPathComponent == "old.txt" }))
    }

    func test_removeLegacyLogArchives_removesArchiveDirectories() throws {
        // GIVEN
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let fileManager = FileManager.default

        // Create simulated log archive directory: /tmp/<UUID>/logs/
        let testArchiveParent = tempDir.appendingPathComponent(UUID().uuidString)
        let logsDirectory = testArchiveParent.appendingPathComponent("logs")
        try fileManager.createDirectory(at: logsDirectory, withIntermediateDirectories: true)

        let dummyLog = logsDirectory.appendingPathComponent("logs.zip")
        try "test".write(to: dummyLog, atomically: true, encoding: .utf8)

        XCTAssertTrue(fileManager.fileExists(atPath: dummyLog.path))

        // WHEN
        try provider.removeLegacyLogArchives()

        // THEN
        XCTAssertFalse(fileManager.fileExists(atPath: testArchiveParent.path))
    }

    func test_removeLegacyLogArchives_doesNotDeleteUnrelatedDirectories() throws {
        // GIVEN
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let unrelatedDir = tempDir.appendingPathComponent("UnrelatedTempFolder")
        try FileManager.default.createDirectory(at: unrelatedDir, withIntermediateDirectories: true)

        XCTAssertTrue(FileManager.default.fileExists(atPath: unrelatedDir.path))

        // WHEN
        try provider.removeLegacyLogArchives()

        // THEN
        XCTAssertTrue(FileManager.default.fileExists(atPath: unrelatedDir.path))
        try? FileManager.default.removeItem(at: unrelatedDir)
    }

    func test_logsDirectoryExists_shouldNotThrow_whenGeneratingLogsZip() throws {
        // GIVEN
        let logsDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("logs")
        try FileManager.default.createDirectory(at: logsDirectory, withIntermediateDirectories: true)
        XCTAssertTrue(FileManager.default.fileExists(atPath: logsDirectory.path))

        // WHEN
        let zipURL = try provider.generateLogFilesZip()

        // THEN
        XCTAssertTrue(FileManager.default.fileExists(atPath: zipURL.path))
        try? FileManager.default.removeItem(at: logsDirectory)
    }

    func test_logsDirectoryIsMissing_shouldCreateIt() throws {
        // GIVEN
        let logsDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("logs")
        try? FileManager.default.removeItem(at: logsDirectory)

        // WHEN
        XCTAssertNoThrow(try provider.generateLogFilesZip())

        // THEN
        XCTAssertTrue(FileManager.default.fileExists(atPath: logsDirectory.path))
    }

}
