//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

@testable import Wire
import XCTest

final class DebugLogSenderTests: XCTestCase {

    func testExistingDebugLogsOnlyReturnsULRsForExistingFiles() throws {
        let fileManager = PartialMockFileManager()

        fileManager.existingFilePaths = [ZMSLog.currentLogURL.path]
        XCTAssertTrue(
            DebugLogSender.existingDebugLogs(fileManager: fileManager).contains(ZMSLog.currentLogURL)
        )

        fileManager.existingFilePaths = []
        XCTAssertFalse(
            DebugLogSender.existingDebugLogs(fileManager: fileManager).contains(ZMSLog.currentLogURL)
        )
    }
}

private class PartialMockFileManager: FileManager {

    var existingFilePaths: [String] = []

    override func fileExists(atPath path: String) -> Bool {
        existingFilePaths.contains(path)
    }
}
