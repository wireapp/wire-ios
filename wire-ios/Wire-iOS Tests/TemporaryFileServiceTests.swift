//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

import XCTest
@testable import Wire

class TemporaryFileServiceTests: XCTestCase {
    var sut: TemporaryFileService!

    override func setUp() {
        super.setUp()
        sut = TemporaryFileService()
        sut.removeTemporaryData()
    }

    // MARK: - Tests

    func testThatDirectoryContentIsRemoved() throws {
        // Given
        let tmpDirPath = URL(fileURLWithPath: NSTemporaryDirectory())
        let tempUrl = tmpDirPath.appendingPathComponent("testFile.txt")
        let testData = "Test Message"
        try testData.write(to: tempUrl, atomically: true, encoding: .utf8)
        let fCount = try FileManager.default.contentsOfDirectory(atPath: tmpDirPath.path).count
        XCTAssertEqual(fCount, 1)
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempUrl.path))

        // When
        sut.removeTemporaryData()

        // Then
        let fileCount = try FileManager.default.contentsOfDirectory(
            atPath: tmpDirPath.path
        ).count

        XCTAssertEqual(fileCount, 0)
        XCTAssertFalse(FileManager.default.fileExists(atPath: tempUrl.path))
    }
}
