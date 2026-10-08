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
}
